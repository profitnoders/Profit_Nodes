#!/bin/bash

# Цветовые обозначения для вывода сообщений
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Сброс цвета

# Функция отображения логотипа
function show_logo() {
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${CYAN}        Добро пожаловать в скрипт управления нодой Waku        ${NC}"
    echo -e "${GREEN}==========================================================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Проверка и установка curl, если он отсутствует
if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}Устанавливаем curl...${NC}"
    sudo apt update
    sudo apt install curl -y
fi

# Функция установки необходимых пакетов
function install_dependencies() {
    echo -e "${BLUE}Устанавливаем необходимые зависимости...${NC}"
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop \
        nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip
}

# Функция установки Docker и Docker Compose
function install_docker() {
    echo -e "${BLUE}Проверяем Docker...${NC}"
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com | sh
    fi

    echo -e "${BLUE}Проверяем Docker Compose...${NC}"
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Устанавливаем Docker Compose...${NC}"
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
}

# Установка ноды Waku
function install_node() {
    install_dependencies
    install_docker

    cd $HOME
    git clone https://github.com/waku-org/nwaku-compose
    cd nwaku-compose
    cp .env.example .env

    echo -e "${YELLOW}Вставьте ваш RPC для Ethereum Sepolia:${NC}"
    read RPC_URL
    echo -e "${YELLOW}Ваш приватный ключ от EVM кошелька:${NC}"
    read ETH_KEY
    echo -e "${YELLOW}Установите пароль для RLN Membership:${NC}"
    read RLN_PASSWORD

    sed -i "s|RLN_RELAY_ETH_CLIENT_ADDRESS=.*|RLN_RELAY_ETH_CLIENT_ADDRESS=$RPC_URL|" .env
    sed -i "s|ETH_TESTNET_KEY=.*|ETH_TESTNET_KEY=$ETH_KEY|" .env
    sed -i "s|RLN_RELAY_CRED_PASSWORD=.*|RLN_RELAY_CRED_PASSWORD=$RLN_PASSWORD|" .env

    ./register_rln.sh

    echo -e "${BLUE}Запускаем контейнеры Waku...${NC}"
    docker-compose up -d

}

# Обновление ноды Waku
function update_node() {
    cd $HOME/nwaku-compose
    docker-compose down
    sudo rm -r keystore rln_tree
    git pull origin master
    ./register_rln.sh
    docker-compose up -d

    echo -e "${GREEN}Обновление завершено!${NC}"
}

# Просмотр логов ноды
function view_logs() {
    echo -e "${BLUE}Просмотр логов ноды Waku...${NC}"
    cd $HOME/nwaku-compose
    docker-compose logs -f
}

# Удаление ноды Waku
function remove_node() {
    echo -e "${BLUE}Удаляем ноду Waku...${NC}"
    cd $HOME/nwaku-compose
    docker-compose down
    cd $HOME
    rm -rf nwaku-compose
    echo -e "${GREEN}Нода успешно удалена!${NC}"
}

# Главное меню
function show_menu() {
    show_logo
    echo -e "${CYAN}1) 🚀 Установить ноду${NC}"
    echo -e "${CYAN}2) 🔄 Обновить ноду${NC}"
    echo -e "${CYAN}3) 📜 Просмотр логов${NC}"
    echo -e "${CYAN}4) 🗑️ Удалить ноду${NC}"
    echo -e "${CYAN}5) ❌ Выйти${NC}"

    echo -e "${YELLOW}Выберите действие:${NC}"
    read choice

    case $choice in
        1) install_node ;;
        2) update_node ;;
        3) view_logs ;;
        4) remove_node ;;
        5) echo -e "${GREEN}Выход...${NC}" && exit 0 ;;
        *) echo -e "${RED}Неверный выбор! Попробуйте снова.${NC}" && show_menu ;;
    esac
}

# Запуск меню
show_menu
