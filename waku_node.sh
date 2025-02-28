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
    echo -e "${CLR_INFO}        Добро пожаловать в скрипт управления нодой Waku        ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция установки необходимых пакетов
function install_dependencies() {
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop \
        nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip
    # Проверка и установка curl, если он отсутствует
    if ! command -v curl &> /dev/null; then
        sudo apt update
        sudo apt install curl -y
    fi
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com | sh
    fi

    if ! command -v docker-compose &> /dev/null; then
        sudo apt update && sudo apt install -y docker-compose
        command -v docker-compose &> /dev/null && echo -e "${CLR_INFO}Docker Compose успешно установлен!${CLR_RESET}" || { echo -e "\033[1;31;40mОшибка установки.${CLR_RESET}"; exit 1; }
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

    echo -e "${CLR_INFO}Вставьте ваш RPC Sepolia ETH:${CLR_RESET}"
    read RPC
    
    echo -e "${CLR_INFO}\nВставьте ваш приватный ключ от EVM кошелька, на котором есть Sepolia ETH:${CLR_RESET}"
    read PRIVATE_KEY
    
    echo -e "${CLR_INFO}\nУстановите пароль:${CLR_RESET}"
    read PASSWORD


    sed -i "s|RLN_RELAY_ETH_CLIENT_ADDRESS=.*|RLN_RELAY_ETH_CLIENT_ADDRESS=$RPC|" .env
    sed -i "s|ETH_TESTNET_KEY=.*|ETH_TESTNET_KEY=$PRIVATE_KEY|" .env
    sed -i "s|RLN_RELAY_CRED_PASSWORD=.*|RLN_RELAY_CRED_PASSWORD=$PASSWORD|" .env

    ./register_rln.sh

    docker-compose up -d
}

# Обновление ноды Waku
function update_node() {
    cd $HOME/nwaku-compose
    docker-compose down
    sudo rm -r keystore rln_tree
    git pull origin master
    ./register_rln.sh
    docker compose pull
    docker-compose up -d

    echo -e "${CLR_INFO}Обновление завершено!${CLR_RESET}"
}

# Просмотр логов ноды
function view_logs() {
    echo -e "${CLR_INFO}Просмотр логов ноды Waku...${CLR_RESET}"
    cd $HOME/nwaku-compose && docker-compose logs -f
}

# Удаление ноды Waku
function remove_node() {
    cd $HOME/nwaku-compose
    docker-compose down
    cd $HOME
    rm -rf nwaku-compose
    rm -rf waku_node.sh
    echo -e "${CLR_INFO}Нода успешно удалена!${CLR_RESET}"
}

# Главное меню
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN} 1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN} 2) 📜 Просмотр логов${CLR_RESET}"
    echo -e "${CLR_GREEN} 3) 🔄 Обновить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN} 4) 🗑️ Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN} 5) ❌ Выйти${CLR_RESET}"

    echo -e "${CLR_INFO}Выберите действие:${CLR_RESET}"
    read choice

    case $choice in
        1) install_node ;;
        2) view_logs ;;
        3) update_node ;;
        4) remove_node ;;
        5) echo -e "${CLR_INFO}Выход...${CLR_RESET}" && exit 0 ;;
        *) echo -e "${CLR_INFO}Неверный выбор! Попробуйте снова.${CLR_RESET}" && show_menu ;;
    esac
}

# Запуск меню
show_menu
