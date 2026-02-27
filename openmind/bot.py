import requests, json, random, time, threading
from datetime import datetime, timedelta, timezone
from pathlib import Path

CONFIG_PATH = Path("config.json")
KEYS_PATH = Path("api_keys.txt")
PROMPTS_PATH = Path("prompts.txt")

MSK = timezone(timedelta(hours=3))

# === Загрузка конфигурации ===
with open(CONFIG_PATH) as f:
    config = json.load(f)

MIN_DELAY = config.get("min_delay", 48)
MAX_DELAY = config.get("max_delay", 108)
MODELS = config.get("models", [])

# === Загрузка ключей и промптов ===
with open(KEYS_PATH) as f:
    api_keys = [line.strip() for line in f if line.strip()]

with open(PROMPTS_PATH, encoding="utf-8") as f:
    prompts = [line.strip() for line in f if line.strip()]

def log(text, prefix=""):
    now = datetime.now(MSK).strftime('%Y-%m-%d %H:%M:%S')
    print(f"[{now}] {prefix}{text}")

def build_payload(provider: str, model: str, prompt: str) -> dict:
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
    }

    # По умолчанию (большинство моделей)
    payload["max_tokens"] = 512
    payload["temperature"] = 0.7

    # Особые правила для openai/gpt-5-mini (и часто для всей линейки gpt-5*)
    if provider == "openai" and model.startswith("gpt-5"):
        payload.pop("max_tokens", None)
        payload["max_completion_tokens"] = 512
        payload.pop("temperature", None)  # temperature не поддерживается -> убрать

    return payload


def send_prompt(prompt: str, api_key: str) -> str:
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
        return f"[{provider}/{model}] {data['choices'][0]['message']['content']}"
    except Exception as e:
        return f"[❌ {provider}/{model}] {type(e).__name__}: {e}"
        
def worker_loop(api_key: str, index: int):
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
