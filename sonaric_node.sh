#!/bin/bash

# Оформление текста: цвета и фоны
CLR_INFO='\033[1;97;44m'  # Белый текст на синем фоне
CLR_SUCCESS='\033[1;30;42m'  # Зеленый текст на черном фоне
CLR_WARNING='\033[1;37;41m'  # Белый текст на красном фоне
CLR_ERROR='\033[1;31;40m'  # Красный текст на черном фоне
CLR_RESET='\033[0m'  # Сброс форматирования
CLR_GREEN='\033[0;32m' #Зеленый текст

# Функция отображения логотипа
function show_logo() {
    echo -e "${CLR_INFO}       Добро пожаловать в скрипт управления нодой Sonaric       ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция проверки и установки зависимостей
function install_dependencies() {
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y git jq build-essential gcc unzip wget lz4 bc
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
}

# Установка ноды
function install_node() {
    install_dependencies

    sh -c "$(curl -fsSL http://get.sonaric.xyz/scripts/install.sh)"
    sleep 5
    
    sonaric node-info
}

# Обновление ноды
function update_node() {
    sh -c "$(curl -fsSL http://get.sonaric.xyz/scripts/install.sh)"
    echo -e "${CLR_SUCCESS}Обновлено!${CLR_RESET}"
    sonaric node-info
}

# Проверка работы ноды
function check_node_status() {
    sonaric node-info
}

# Проверка поинтов
function check_points() {
    echo -e "${CLR_SUCCESS}Нафармленные поинты:${CLR_RESET}"
    sonaric points
}

# Бекап ноды
function backup_node() {
    echo -e "${CLR_ERROR}Укажите ваше название ноды при установке :${CLR_RESET}"
    read NODE_NAME

    sonaric identity-export -o "$NODE_NAME.identity"

    echo -e "${CLR_SUCCESS}Резервный файл создан: ${NODE_NAME}.identity${CLR_RESET}"
    cd && cat "${NODE_NAME}.identity"
}

# Регистрация ноды
function register_node() {
    echo -e "${CLR_ERROR}Чтобы зарегистрировать ноду, укажите код из Discord:${CLR_RESET}"
    read DISCORD_CODE

    if [ -z "$DISCORD_CODE" ]; then
        echo -e "${CLR_ERROR}Ошибка: код не может быть пустым.${CLR_RESET}"
        exit 1
    fi

    sonaric node-register "$DISCORD_CODE"
}

# Удаление ноды
function remove_node() {
    sudo systemctl stop sonaricd
    sudo rm -rf $HOME/.sonaric
    echo -e "${CLR_SUCCESS}Нода удалена!${CLR_RESET}"
}

# Главное меню
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 🔄 Обновить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 📜 Проверить состояние ноды${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 🏆 Проверить поинты${CLR_RESET}"
    echo -e "${CLR_GREEN}5) 💾 Создать бекап ноды${CLR_RESET}"
    echo -e "${CLR_GREEN}6) 🔑 Зарегистрировать ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}7) 🗑️ Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}8) ❌ Выйти${CLR_RESET}"

    echo -e "${CLR_WARNING}Выберите номер действия:${CLR_RESET}"
    read -r choice

    case $choice in
        1) install_node ;;
        2) update_node ;;
        3) check_node_status ;;
        4) check_points ;;
        5) backup_node ;;
        6) register_node ;;
        7) remove_node ;;
        8) echo -e "${CLR_WARNING}Выход...${CLR_RESET}" && exit 0 ;;
        *) echo -e "${CLR_WARNING}Неверный выбор! Попробуйте снова.${CLR_RESET}" && show_menu ;;
    esac
}


# Запуск меню
show_menu
