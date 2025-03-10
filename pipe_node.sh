#!/bin/bash

# Цвета для оформления текста
CLR_INFO='\033[1;97;44m'  # Белый текст на синем фоне
CLR_SUCCESS='\033[1;30;42m'  # Зеленый текст на черном фоне
CLR_WARNING='\033[1;37;41m'  # Белый текст на красном фоне
CLR_ERROR='\033[1;31;40m'  # Красный текст на черном фоне
CLR_RESET='\033[0m'  # Сброс форматирования

# Функция для отображения логотипа
function show_logo() {
    echo -e "${CLR_INFO}      Добро пожаловать в скрипт управления нодой Hyperlane      ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция для установки зависимостей
function install_dependencies() {
    echo -e "${CLR_INFO}▶ Обновляем систему и устанавливаем зависимости...${CLR_RESET}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y screen curl
}

# Функция установки ноды
function install_node() {
    echo -e "${CLR_INFO}▶ Устанавливаем ноду Pipe...${CLR_RESET}"
    curl -L -o pop https://dl.pipecdn.app/v0.2.8/pop
    chmod +x pop
    mkdir -p download_cache

    echo -e "${CLR_SUCCESS}✅ Установка ноды Pipe завершена!${CLR_RESET}"
}

# Функция запуска ноды
function start_node() {
    echo -e "${CLR_INFO}▶ Запуск ноды Pipe в screen сессии...${CLR_RESET}"
    
    read -p "Введите ваш Solana кошелек (pubKey): " WALLET_KEY
    read -p "Введите объем RAM для ноды (в ГБ, например 4): " RAM
    read -p "Введите макс. объем диска (в ГБ, например 100): " DISK

    screen -dmS pipe_node ./pop --ram "$RAM" --max-disk "$DISK" --cache-dir ./download_cache --pubKey "$WALLET_KEY"

    echo -e "${CLR_SUCCESS}✅ Нода Pipe успешно запущена в screen сессии 'pipe_node'!${CLR_RESET}"
}

# Функция просмотра статуса ноды
function check_status() {
    echo -e "${CLR_INFO}▶ Просмотр метрик ноды...${CLR_RESET}"
    ./pop --status
}

# Функция проверки поинтов
function check_points() {
    echo -e "${CLR_INFO}▶ Проверка заработанных поинтов...${CLR_RESET}"
    ./pop --points
}

# Функция регистрации по реферальному коду
function signup_referral() {
    read -p "Введите реферальный код: " REF_CODE
    echo -e "${CLR_INFO}▶ Регистрация с реферальным кодом...${CLR_RESET}"
    ./pop --signup-by-referral-route "$REF_CODE"
}

# Функция удаления ноды
function remove_node() {
    read -p "⚠ Вы уверены, что хотите удалить ноду Pipe? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" ]]; then
        echo -e "${CLR_WARNING}▶ Удаление ноды Pipe...${CLR_RESET}"
        pkill -f pop
        rm -rf pop download_cache
        echo -e "${CLR_SUCCESS}✅ Нода Pipe успешно удалена!${CLR_RESET}"
    else
        echo -e "${CLR_INFO}▶ Отмена удаления.${CLR_RESET}"
    fi
}

# Меню управления
function show_menu() {
    show_logo 
    echo -e "${CLR_SUCCESS} Добро пожаловать в установщик ноды Pipe ${CLR_RESET}"
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) ▶  Запустить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 📊 Проверить статус ноды${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 💰 Проверить поинты${CLR_RESET}"
    echo -e "${CLR_GREEN}5) 🔗 Зарегистрировать ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}6) 🗑️  Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}7) ❌ Выйти${CLR_RESET}"
    echo -e "${CLR_INFO}Введите номер действия:${CLR_RESET}"
    read -r choice

    case $choice in
        1) install_dependencies && install_node ;;
        2) start_node ;;
        3) check_status ;;
        4) check_points ;;
        5) signup_referral ;;
        6) remove_node ;;
        7) echo -e "${CLR_ERROR}Выход...${CLR_RESET}" ;;
        *) echo -e "${CLR_WARNING}Неверный выбор. Попробуйте снова.${CLR_RESET}" && show_menu ;;
    esac
}

# Запуск меню
show_menu
