import requests, json, random, time, threading
from datetime import datetime, timedelta, timezone
from pathlib import Path

CONFIG_PATH = Path("config.json")
KEYS_PATH = Path("api_keys.txt")
PROMPTS_PATH = Path("prompts.txt")

MSK = timezone(timedelta(hours=3))

with open(CONFIG_PATH, encoding="utf-8") as f:
    config = json.load(f)

MIN_DELAY = int(config.get("min_delay", 48))
MAX_DELAY = int(config.get("max_delay", 108))
MODELS = config.get("models", [])

with open(KEYS_PATH, encoding="utf-8") as f:
    api_keys = [line.strip() for line in f if line.strip()]

with open(PROMPTS_PATH, encoding="utf-8") as f:
    prompts = [line.strip() for line in f if line.strip()]

def log(text, prefix=""):
    now = datetime.now(MSK).strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{now}] {prefix}{text}")

def extract_text(data: dict) -> str:
    """
    Поддерживает:
    - message.content как строку
    - message.content как список частей [{"type":"text","text":"..."}]
    - fallback на другие поля если провайдер вернул нестандартно
    """
    try:
        choice0 = (data.get("choices") or [])[0]
    except Exception:
        return ""

    msg = choice0.get("message") or {}
    content = msg.get("content", "")

    # 1) классика: строка
    if isinstance(content, str):
        return content.strip()

    # 2) новый формат: список частей
    if isinstance(content, list):
        parts = []
        for p in content:
            if isinstance(p, dict):
                if p.get("type") == "text" and isinstance(p.get("text"), str):
                    parts.append(p["text"])
                elif isinstance(p.get("content"), str):  # на всякий
                    parts.append(p["content"])
            elif isinstance(p, str):
                parts.append(p)
        return "\n".join([x for x in parts if x]).strip()

    # 3) fallback
    return str(content).strip()

def build_payload(provider: str, model: str, prompt: str) -> dict:
    # как в твоём curl: system + user
    messages = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": prompt},
    ]

    payload = {"model": model, "messages": messages}

    # gpt-5*: max_completion_tokens и без temperature
    if provider == "openai" and model.startswith("gpt-5"):
        payload["max_completion_tokens"] = 512
        return payload

    # остальные: обычные параметры (по докам OpenMind для chat/completions)
    payload["max_tokens"] = 512
    payload["temperature"] = 0.7
    return payload

def send_prompt(prompt: str, api_key: str) -> str:
    if not MODELS:
        return "[❌] config.json: models пустой"
    model_config = random.choice(MODELS)
    provider = model_config["provider"]
    model = model_config["model"]

    api_url = f"https://api.openmind.org/api/core/{provider}/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    payload = build_payload(provider, model, prompt)

    try:
        r = requests.post(api_url, headers=headers, json=payload, timeout=60)

        if not r.ok:
            return f"[❌ {provider}/{model}] HTTP {r.status_code} | {r.text[:500]}"

        data = r.json()
        text = extract_text(data)

        # если текст пустой — выведем кусок сырого ответа, чтобы понять формат
        if not text:
            raw = json.dumps(data, ensure_ascii=False)[:800]
            return f"[⚠️ {provider}/{model}] Пустой текст. RAW: {raw}"

        return f"[{provider}/{model}] {text}"

    except Exception as e:
        return f"[❌ {provider}/{model}] {type(e).__name__}: {e}"

def worker_loop(api_key: str, index: int):
    if not prompts:
        log("❌ prompts.txt пустой", f"🔑 Ключ №{index + 1} | ")
        return

    prompt_id = 1
    prefix = f"🔑 Ключ №{index + 1} | "
    while True:
        prompt = random.choice(prompts)
        log(f"📨 Запрос #{prompt_id}", prefix)
        log(f"🟡 Промпт: {prompt}", prefix)
        reply = send_prompt(prompt, api_key)
        log(f"💬 Ответ: {reply}", prefix)

        delay = random.randint(MIN_DELAY, MAX_DELAY)
        log(f"⏳ Ожидание {delay} сек...\n", prefix)
        prompt_id += 1
        time.sleep(delay)

def main():
    if not api_keys:
        log("❌ api_keys.txt пустой — нет ключей")
        return

    threads = []
    for i, key in enumerate(api_keys):
        t = threading.Thread(target=worker_loop, args=(key, i), daemon=True)
        t.start()
        threads.append(t)
        time.sleep(1)

    while True:
        time.sleep(60)

if __name__ == "__main__":
    main()