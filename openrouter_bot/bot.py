import os
import json
import random
import requests
import time
import threading

WORKDIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_FILE = os.path.join(WORKDIR, "config.json")
KEYS_FILE = os.path.join(WORKDIR, "api_keys.txt")
PROMPTS_FILE = os.path.join(WORKDIR, "prompts.txt")

def load_config():
    with open(CONFIG_FILE) as f:
        return json.load(f)

def load_keys():
    with open(KEYS_FILE) as f:
        return [k.strip() for k in f if k.strip()]

def load_prompts():
    with open(PROMPTS_FILE) as f:
        return [p.strip() for p in f if p.strip()]

def choose_random(lst):
    return random.choice(lst)

def call_openrouter(api_key, model, prompt):
    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    data = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}]
    }

    response = requests.post(url, headers=headers, json=data)
    if response.status_code == 200:
        return response.json()["choices"][0]["message"]["content"]
    else:
        print(f"[!] Ошибка {response.status_code}: {response.text}")
        return None

def worker(api_key):
    while True:
        model = choose_random(models)
        prompt = choose_random(prompts)
        short_key = api_key[:14] + "..."
        print(f"\n=== 🔑 Ключ: {short_key} | 🤖 Модель: {model} | 📝 Промпт: {prompt} ===")
        try:
            reply = call_openrouter(api_key, model, prompt)
            if reply:
                print(f"📩 Ответ: {reply}\n")
        except Exception as e:
            print(f"[!] Ошибка: {e}")

        delay = random.randint(min_delay, max_delay)
        print(f"⏳ [{short_key}] Ждёт {delay} сек...")
        time.sleep(delay)

def main():
    config = load_config()
    keys = load_keys()
    prompts = load_prompts()
    global models, min_delay, max_delay
    models = config.get("models", ["openai/gpt-3.5-turbo"])
    min_delay = config.get("min_delay", 10)
    max_delay = config.get("max_delay", 30)

    if not keys:
        print("[!] Нет ключей.")
        return
    if not prompts:
        print("[!] Нет промптов.")
        return

    print(f"▶️ Запуск потоков для {len(keys)} ключей...\n")
    for key in keys:
        threading.Thread(target=worker, args=(key,), daemon=True).start()

    while True:
        time.sleep(9999)  

if __name__ == "__main__":
    main()
