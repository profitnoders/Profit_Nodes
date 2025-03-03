import requests
import random
import time
import logging
from faker import Faker

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
    elif style == "scientific":
        question = f"How does {faker.word()} impact modern physics and AI development?"
    elif style == "business":
        question = f"What are the key strategies for scaling a startup in the {faker.word()} industry?"
    elif style == "historical":
        question = f"How did {faker.word()} influence world history and technological progress?"
    elif style == "creative":
        question = f"Write a short sci-fi story about {faker.word()} becoming a sentient AI."
    elif style == "motivational":
        question = f"What are the top three ways to stay motivated while working on {faker.word()}?"

    return style, question

# Функция отправки запроса к AI
def send_request(api_key: str, base_url: str, question: str) -> str:
    headers = {"Content-Type": "application/json", "Authorization": f"Bearer {api_key}"}
    payload = {"model": "qwen2-0.5b-instruct", "messages": [{"role": "user", "content": question}], "temperature": 0.7}

    for attempt in range(100):
        try:
            logging.info(f"Запрос {attempt + 1}: {question[:50]}...")
            response = requests.post(f"{base_url}/v1/chat/completions", headers=headers, json=payload, timeout=30)

            if response.status_code == 200:
                return response.json()["choices"][0]["message"]["content"]

            logging.warning(f"Ошибка API ({response.status_code}): {response.text}")
            time.sleep(5)

        except Exception as e:
            logging.error(f"Ошибка соединения: {e}")
            time.sleep(5)

    raise Exception("Достигнуто максимальное количество попыток")

# Функция работы бота
def run_chatbot(api_key: str, base_url: str):
    while True:
        style, question = generate_question()

        logging.info(f"\n[СТИЛЬ: {style.upper()}] Вопрос: {question}")

        try:
            response = send_request(api_key, base_url, question)
            print(f"\n[{style.upper()}]\n👤 Вопрос: {question}\n🤖 Ответ: {response}\n")

            logging.info(f"Ответ получен: {response}")
            time.sleep(1)

        except Exception as e:
            logging.error(f"Ошибка обработки вопроса: {e}")
            continue

# Основной запуск
def main():
    api_key = input("🔑 Введите ваш API ключ: ")
    domain_name = input("🌐 Введите имя домена (например, antonprofit): ")
    
    base_url = f"https://{domain_name}.gaia.domains"
    
    logging.info(f"Используемый домен: {base_url}")
    
    run_chatbot(api_key, base_url)

if __name__ == "__main__":
    main()
