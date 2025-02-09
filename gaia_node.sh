#!/bin/bash

# Цветовые коды
CLR_INFO='\033[1;36m'  # Голубой цвет
CLR_SUCCESS='\033[1;32m'  # Зеленый цвет
CLR_WARNING='\033[1;33m'  # Желтый цвет
CLR_ERROR='\033[1;31m'  # Красный цвет
CLR_RESET='\033[0m'  # Сброс цвета

# Функция отображения логотипа
function show_logo() {
    echo -e "${CLR_SUCCESS}==========================================================${CLR_RESET}"
    echo -e "${CLR_INFO}         Добро пожаловать в установщик Gaianet Node       ${CLR_RESET}"
    echo -e "${CLR_SUCCESS}==========================================================${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Установка ноды Gaianet
function install_node() {
    echo -e "${CLR_INFO}▶ Обновляем систему...${CLR_RESET}"
    sudo apt update -y
    sudo apt-get update -y
    sleep 2

    echo -e "${CLR_INFO}▶ Устанавливаем ноду Gaianet...${CLR_RESET}"
    curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash
    sleep 3

    echo -e "${CLR_INFO}▶ Обновляем конфигурацию...${CLR_RESET}"
    echo "export PATH=\$PATH:$HOME/gaianet/bin" >> $HOME/.bashrc
    sleep 5
    source ~/.bashrc
    sleep 9

    echo -e "${CLR_INFO}▶ Инициализируем узел с конфигурацией...${CLR_RESET}"
    gaianet init --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json
    sleep 3

    #sed -i 's/"llamaedge_port": "8080"/"llamaedge_port": "8781"/g' ~/gaianet/config.json

    echo -e "${CLR_SUCCESS}✅ Установка ноды завершена!${CLR_RESET}"
}

# Запуск ноды
function start_node() {
    echo -e "${CLR_INFO}▶ Запускаем ноду Gaianet...${CLR_RESET}"
    gaianet start
    echo -e "${CLR_SUCCESS}✅ Нода запущена!${CLR_RESET}"
}

# Получение информации о ноде
function get_node_info() {
    echo -e "${CLR_INFO}▶ Получаем информацию о ноде...${CLR_RESET}"
    gaianet info
}

# Установка и запуск бота
function setup_bot() {
    echo -e "${CLR_INFO}▶ Устанавливаем необходимые пакеты...${CLR_RESET}"
    sudo apt update -y
    sudo apt install -y python3-pip python3-dev python3-venv curl git
    sudo apt install nano -y
    sudo apt install screen -y
    pip3 install aiohttp

    echo -e "${CLR_INFO}▶ Устанавливаем библиотеки Python...${CLR_RESET}"
    pip install requests faker

    echo -e "${CLR_INFO}▶ Получаем Node ID для подстановки в бота...${CLR_RESET}"
    NODE_ID=$(gaianet info | awk -F': ' '/Node ID/{print $2}' | tr -d '[:space:]' | sed 's/\x1B\[[0-9;]*[mK]//g')

    if [[ -z "$NODE_ID" ]]; then
        echo -e "${CLR_ERROR}❌ Не удалось получить Node ID. Проверьте работу ноды!${CLR_RESET}"
        exit 1
    fi

    echo -e "${CLR_SUCCESS}✅ Node ID: $NODE_ID${CLR_RESET}"

    echo -e "${CLR_INFO}▶ Создаём скрипт бота...${CLR_RESET}"
    cat <<EOF > ~/random_chat_with_faker.py
import requests
import random
import logging
import time
from faker import Faker
from datetime import datetime

node_url = "https://$NODE_ID.gaia.domains/v1/chat/completions" 
faker = Faker()

headers = {
    "accept": "application/json",
    "Content-Type": "application/json"
}

logging.basicConfig(filename='chat_log.txt', level=logging.INFO, format='%(asctime)s - %(message)s')

def log_message(node, message):
    logging.info(f"{node}: {message}")

def send_message(node_url, message):
    try:
        response = requests.post(node_url, json=message, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Failed to get response from API: {e}")
        return None

def extract_reply(response):
    if response and 'choices' in response:
        return response['choices'][0]['message']['content']
    return ""

while True:
    random_question = faker.sentence(nb_words=10)
    message = {
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": random_question}
        ]
    }
    question_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    response = send_message(node_url, message)
    reply = extract_reply(response)
    reply_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_message("Node replied", f"Q ({question_time}): {random_question} A ({reply_time}): {reply}")
    print(f"Q ({question_time}): {random_question}\nA ({reply_time}): {reply}")
    delay = random.randint(60, 180)
    time.sleep(delay)
EOF

    echo -e "${CLR_INFO}▶ Запускаем бота в screen-сессии...${CLR_RESET}"
    screen -S faker_session -dm python3 ~/random_chat_with_faker.py

    echo -e "${CLR_SUCCESS}✅ Бот успешно запущен!${CLR_RESET}"
}

# Удаление ноды
function remove_node() {
    echo -e "${CLR_WARNING}⚠ Удаляем ноду Gaianet...${CLR_RESET}"
    gaianet stop
    rm -rf ~/.gaianet

    echo -e "${CLR_SUCCESS}✅ Нода удалена!${CLR_RESET}"
}

# Меню управления
function show_menu() {
    show_logo
    echo -e "${CLR_INFO}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_INFO}2) ▶ Запустить ноду${CLR_RESET}"
    echo -e "${CLR_INFO}3) 📜 Получить информацию о ноде${CLR_RESET}"
    echo -e "${CLR_INFO}4) 🤖 Создать бота${CLR_RESET}"
    echo -e "${CLR_INFO}5) 🗑 Удалить ноду${CLR_RESET}"
    echo -e "${CLR_INFO}6) ❌ Выйти${CLR_RESET}"

    read -r choice

    case $choice in
        1) install_node ;;
        2) start_node ;;
        3) get_node_info ;;
        4) setup_bot ;;
        5) remove_node ;;
        6) exit 0 ;;
        *) echo -e "${CLR_ERROR}❌ Ошибка: Неверный ввод!${CLR_RESET}" && show_menu ;;
    esac
}

# Запуск меню
show_menu
