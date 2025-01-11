#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Сброс цвета

# Логотип
function show_logo() {
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${CYAN}     Добро пожаловать в скрипт установки ноды Unichain     ${NC}"
    echo -e "${GREEN}==========================================================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Установка необходимых пакетов
function install_dependencies() {
    echo -e "${YELLOW}Обновляем систему и устанавливаем зависимости...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl git docker.io
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
}

# Установка ноды
function install_node() {
    echo -e "${BLUE}Начинаем установку ноды Unichain...${NC}"
    install_dependencies

    # Клонируем репозиторий
    if [ ! -d "$HOME/unichain-node" ]; then
        echo -e "${BLUE}Клонируем репозиторий Uniswap Unichain Node...${NC}"
        git clone https://github.com/Uniswap/unichain-node $HOME/unichain-node
    else
        echo -e "${BLUE}Папка unichain-node уже существует. Пропускаем клонирование.${NC}"
    fi

    cd $HOME/unichain-node || { echo -e "${RED}Ошибка: не удалось войти в директорию unichain-node.${NC}"; exit 1; }

    # Настройка .env.sepolia
    if [ -f ".env.sepolia" ]; then
        echo -e "${BLUE}Обновляем файл .env.sepolia...${NC}"
        sed -i 's|^OP_NODE_L1_ETH_RPC=.*|OP_NODE_L1_ETH_RPC=https://ethereum-sepolia-rpc.publicnode.com|' .env.sepolia
        sed -i 's|^OP_NODE_L1_BEACON=.*|OP_NODE_L1_BEACON=https://ethereum-sepolia-beacon-api.publicnode.com|' .env.sepolia
    else
        echo -e "${RED}Ошибка: файл .env.sepolia не найден.${NC}"
        exit 1
    fi

    # Запускаем контейнеры
    echo -e "${BLUE}Запускаем контейнеры с помощью docker-compose...${NC}"
    docker-compose up -d

    echo -e "${GREEN}Установка завершена! Нода запущена.${NC}"
}

# Обновление ноды
function update_node() {
    echo -e "${BLUE}Обновляем ноду Unichain...${NC}"
    cd $HOME/unichain-node || { echo -e "${RED}Ошибка: не удалось войти в директорию unichain-node.${NC}"; exit 1; }
    docker-compose pull
    docker-compose up -d
    echo -e "${GREEN}Нода успешно обновлена.${NC}"
}

# Проверка логов
function check_logs() {
    echo -e "${BLUE}Просмотр логов Unichain...${NC}"
    cd $HOME/unichain-node || { echo -e "${RED}Ошибка: не удалось войти в директорию unichain-node.${NC}"; exit 1; }
    docker-compose logs -f
}

# Проверка статуса
function check_status() {
    echo -e "${BLUE}Проверка статуса ноды Unichain...${NC}"
    curl -d '{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
    -H "Content-Type: application/json" http://localhost:8545
}

# Удаление ноды
function remove_node() {
    echo -e "${BLUE}Удаляем ноду Unichain...${NC}"
    cd $HOME/unichain-node || { echo -e "${RED}Ошибка: не удалось войти в директорию unichain-node.${NC}"; exit 1; }
    docker-compose down -v
    cd $HOME
    rm -rf $HOME/unichain-node
    echo -e "${GREEN}Нода успешно удалена.${NC}"
}

# Меню
function show_menu() {
    show_logo
    echo -e "${CYAN}1) ?? Установить ноду${NC}"
    echo -e "${CYAN}2) ?? Обновить ноду${NC}"
    echo -e "${CYAN}3) ?? Проверка логов${NC}"
    echo -e "${CYAN}4) ?? Проверка статуса${NC}"
    echo -e "${CYAN}5) ??? Удалить ноду${NC}"
    echo -e "${CYAN}6) ? Выйти${NC}"

    echo -e "${YELLOW}Выберите действие:${NC}"
    read -r choice
    case $choice in
        1) install_node ;;
        2) update_node ;;
        3) check_logs ;;
        4) check_status ;;
        5) remove_node ;;
        6) echo -e "${GREEN}Выход...${NC}" ;;
        *) echo -e "${RED}Неверный выбор!${NC}" ;;
    esac
}

# Запуск меню
show_menu
