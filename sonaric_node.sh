#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Функция отображения логотипа
function show_logo() {
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${CYAN}       Добро пожаловать в скрипт управления нодой Sonaric       ${NC}"
    echo -e "${GREEN}==========================================================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция проверки и установки зависимостей
function install_dependencies() {
    echo -e "${BLUE}Проверяем и устанавливаем необходимые зависимости...${NC}"
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y git jq build-essential gcc unzip wget lz4 bc
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
}

# Функция проверки версии Ubuntu
function check_ubuntu_version() {
    UBUNTU_VERSION=$(lsb_release -rs)
    REQUIRED_VERSION=22.04

    if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
        echo -e "${RED}Переустановите Ubuntu на версию 22.04.${NC}"
        exit 1
    fi
}

# Установка ноды
function install_node() {
    check_ubuntu_version
    install_dependencies
    echo -e "${BLUE}Устанавливаем ноду Sonaric...${NC}"
    sh -c "$(curl -fsSL http://get.sonaric.xyz/scripts/install.sh)"

    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Команда для проверки состояния ноды:${NC}"
    echo "sonaric node-info"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}Установка завершена!${NC}"
    sonaric node-info
}

# Обновление ноды
function update_node() {
    sh -c "$(curl -fsSL http://get.sonaric.xyz/scripts/install.sh)"
    echo -e "${GREEN}Обновление завершено!${NC}"
    sonaric node-info
}

# Проверка работы ноды
function check_node_status() {
    echo -e "${BLUE}Логи ноды...${NC}"
    sonaric node-info
}

# Проверка поинтов
function check_points() {
    echo -e "${BLUE}Нафармленные поинты:${NC}"
    sonaric points
}

# Бекап ноды
function backup_node() {
    echo -e "${YELLOW}Укажите ваше название ноды при установке :${NC}"
    read NODE_NAME

    sonaric identity-export -o "$NODE_NAME.identity"

    echo -e "${GREEN}Резервный файл создан: ${NODE_NAME}.identity${NC}"
    cd && cat "${NODE_NAME}.identity"
}

# Регистрация ноды
function register_node() {
    echo -e "${YELLOW}Чтобы зарегистрировать ноду, укажите код из Discord:${NC}"
    read DISCORD_CODE

    if [ -z "$DISCORD_CODE" ]; then
        echo -e "${RED}Ошибка: код не может быть пустым.${NC}"
        exit 1
    fi

    sonaric node-register "$DISCORD_CODE"
}

# Удаление ноды
function remove_node() {
    echo -e "${BLUE}Удаляем ноду.${NC}"
    sudo systemctl stop sonaricd
    sudo rm -rf $HOME/.sonaric
    echo -e "${GREEN}Нода удалена!${NC}"
}

# Главное меню
function show_menu() {
    show_logo
    echo -e "${CYAN}1) 🚀 Установить ноду${NC}"
    echo -e "${CYAN}2) 🔄 Обновить ноду${NC}"
    echo -e "${CYAN}3) 📜 Проверить состояние ноды${NC}"
    echo -e "${CYAN}4) 🏆 Проверить поинты${NC}"
    echo -e "${CYAN}5) 💾 Создать бекап ноды${NC}"
    echo -e "${CYAN}6) 🔑 Зарегистрировать ноду${NC}"
    echo -e "${CYAN}7) 🗑️ Удалить ноду${NC}"
    echo -e "${CYAN}8) ❌ Выйти${NC}"

    echo -e "${YELLOW}Выберите номер действия:${NC}"
    read -r choice

    case $choice in
        1) install_node ;;
        2) update_node ;;
        3) check_node_status ;;
        4) check_points ;;
        5) backup_node ;;
        6) register_node ;;
        7) remove_node ;;
        8) echo -e "${GREEN}Выход...${NC}" && exit 0 ;;
        *) echo -e "${RED}Неверный выбор! Попробуйте снова.${NC}" && show_menu ;;
    esac
}


# Запуск меню
show_menu
