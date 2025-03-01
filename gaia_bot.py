import requests
import random
import time
import logging
from faker import Faker

# Конфигурация Domain и модели
CONFIG = {
    "BASE_URL": "https://adminodes.gaia.domains",
    "MODEL": "qwen2-0.5b-instruct",
    "MAX_RETRIES": 100,
    "RETRY_DELAY": 5,
    "QUESTION_DELAY": 1
}
# Логирование
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.FileHandler("chatbot.log"), logging.StreamHandler()]
)
faker = Faker()

# Разные стили вопросов
STYLES = ["formal", "friendly", "technical", "humorous", "philosophical"]

# Функция генерации случайного вопроса
def generate_question():
    style = random.choice(STYLES)
    word_count = random.randint(5, 12)  # Случайная длина вопроса

    if style == "formal":
        question = faker.paragraph(nb_sentences=1)
    elif style == "friendly":
        question = f"{faker.first_name()} asks: {faker.sentence(nb_words=word_count)}"
    elif style == "technical":
        question = f"How does {faker.word()} apply to blockchain technology?"
    elif style == "humorous":
        question = f"Why does {faker.word()} sound like a programming joke?"
    elif style == "philosophical":
        question = f"What is the true meaning of {faker.word()} in the universe?"

    return style, question

# Функция отправки запроса к AI
def send_request(api_key: str, question: str) -> str:
    headers = {"Content-Type": "application/json", "Authorization": f"Bearer {api_key}"}
    payload = {"model": CONFIG["MODEL"], "messages": [{"role": "user", "content": question}], "temperature": 0.7}

    for attempt in range(CONFIG["MAX_RETRIES"]):
        try:
            logging.info(f"Запрос {attempt + 1}: {question[:50]}...")
            response = requests.post(f"{CONFIG['BASE_URL']}/v1/chat/completions", headers=headers, json=payload, timeout=30)

            if response.status_code == 200:
                return response.json()["choices"][0]["message"]["content"]

            logging.warning(f"Ошибка API ({response.status_code}): {response.text}")
            time.sleep(CONFIG["RETRY_DELAY"])

        except Exception as e:
            logging.error(f"Ошибка соединения: {e}")
            time.sleep(CONFIG["RETRY_DELAY"])

    raise Exception("Достигнуто максимальное количество попыток")

# Функция работы бота
def run_chatbot(api_key: str):
    while True:
        style, question = generate_question()

        logging.info(f"\n[СТИЛЬ: {style.upper()}] Вопрос: {question}")

        try:
            response = send_request(api_key, question)
            print(f"\n[{style.upper()}]\n👤 Вопрос: {question}\n🤖 Ответ: {response}\n")

            logging.info(f"Ответ получен: {response}")
            time.sleep(CONFIG["QUESTION_DELAY"])

        except Exception as e:
            logging.error(f"Ошибка обработки вопроса: {e}")
            continue

# Основной запуск
def main():
    api_key = input("🔑 Введите ваш API ключ: ")
    run_chatbot(api_key)

if __name__ == "__main__":
    main()
