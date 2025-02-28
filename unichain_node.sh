#!/bin/bash

# Оформление текста: цвета и фоны
CLR_INFO='\033[1;97;44m'  # Белый текст на синем фоне
CLR_SUCCESS='\033[1;30;42m'  # Зеленый текст на черном фоне
CLR_WARNING='\033[1;37;41m'  # Белый текст на красном фоне
CLR_ERROR='\033[1;31;40m'  # Красный текст на черном фоне
CLR_RESET='\033[0m'  # Сброс форматирования
CLR_GREEN='\033[0;32m' #Зеленый текст

# Логотип
function show_logo() {
    echo -e "${CLR_SUCCESS}     Добро пожаловать в скрипт установки ноды Unichain     ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Установка необходимых пакетов
function install_dependencies() {
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl git docker.io
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
}

# Установка ноды
function install_node() {
    echo -e "${CLR_INFO}Начинаем установку ноды Unichain...${CLR_RESET}"
    install_dependencies

    # Клонируем репозиторий
    if [ ! -d "$HOME/unichain-node" ]; then
        git clone https://github.com/Uniswap/unichain-node $HOME/unichain-node
    else
        echo -e "${CLR_INFO}Папка unichain-node уже существует. Пропускаем.${CLR_RESET}"
    fi

    cd $HOME/unichain-node || exit 1; 

    # Настройка .env.sepolia
    if [ -f ".env.sepolia" ]; then
        echo -e "${CLR_INFO}Обновляем файл .env.sepolia...${CLR_RESET}"
        sed -i 's|^OP_NODE_L1_ETH_RPC=.*|OP_NODE_L1_ETH_RPC=https://ethereum-sepolia-rpc.publicnode.com|' .env.sepolia
        sed -i 's|^OP_NODE_L1_BEACON=.*|OP_NODE_L1_BEACON=https://ethereum-sepolia-beacon-api.publicnode.com|' .env.sepolia
    else
        echo -e "${CLR_ERROR}Ошибка: файл .env.sepolia не найден.${CLR_RESET}"
        exit 1
    fi
    docker-compose up -d
    echo -e "${CLR_SUCCESS}Установка завершена! Нода запущена.${CLR_RESET}"
}

# Обновление ноды
function update_node() {
    echo -e "${CLR_INFO}Обновляем ноду Unichain...${CLR_RESET}"
    cd $HOME/unichain-node ||  exit 1; 
    docker-compose pull
    docker-compose up -d
    echo -e "${CLR_SUCCESS}Нода успешно обновлена.${CLR_RESET}"
}

# Проверка логов
function check_logs() {
    echo -e "${CLR_INFO}Логи Unichain...${CLR_RESET}"
    cd $HOME/unichain-node ||  exit 1; 
    docker-compose logs -f
}

# Проверка статуса
function check_status() {
    curl -d '{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
    -H "Content-Type: application/json" http://localhost:8545
}

# Удаление ноды
function remove_node() {
    cd $HOME/unichain-node || exit 1; 
    docker-compose down -v
    cd $HOME
    rm -rf $HOME/unichain-node
    echo -e "${CLR_SUCCESS}Нода успешно удалена.${CLR_RESET}"
}

# Меню
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) Обновить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}3) Проверка логов${CLR_RESET}"
    echo -e "${CLR_GREEN}4) Проверка статуса${CLR_RESET}"
    echo -e "${CLR_GREEN}5) Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}6) ❌ Выйти${CLR_RESET}"
    



    echo -e "${CLR_INFO}Выберите действие:${CLR_RESET}"
    read -r choice
    case $choice in
        1) install_node ;;
        2) update_node ;;
        3) check_logs ;;
        4) check_status ;;
        5) remove_node ;;
        6) echo -e "${CLR_SUCCESS}Выход...${CLR_RESET}" ;;
        *) echo -e "${CLR_ERROR}Неверный выбор!${CLR_RESET}" ;;
    esac
}

# Запуск меню
show_menu
