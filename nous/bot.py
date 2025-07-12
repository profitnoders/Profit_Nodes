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
MODEL = config.get("model", "DeepHermes-3-Mistral-24B-Preview")
API_URL = "https://inference-api.nousresearch.com/v1/chat/completions"

# === Загрузка ключей и промптов ===
with open(KEYS_PATH) as f:
    api_keys = [line.strip() for line in f if line.strip()]

with open(PROMPTS_PATH, encoding="utf-8") as f:
    prompts = [line.strip() for line in f if line.strip()]

def log(text, prefix=""):
    now = datetime.now(MSK).strftime('%Y-%m-%d %H:%M:%S')
    print(f"[{now}] {prefix}{text}")

def send_prompt(prompt: str, api_key: str) -> str:
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    payload = {
        "model": MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.7,
        "max_tokens": 512
    }

    try:
        response = requests.post(API_URL, headers=headers, json=payload, timeout=60)
        response.raise_for_status()
        return response.json()['choices'][0]['message']['content']
    except Exception as e:
        return f"[❌ Ошибка] {e}"

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
        time.sleep(1)  # чтобы красиво запускались по очереди

    # бесконечно держим main-поток
    while True:
        time.sleep(60)

if __name__ == "__main__":
    main()
