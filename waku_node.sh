#!/bin/bash

# Функция отображения логотипа
function show_logo() {
    echo -e "\033[1;30;42m==========================================================\033[0m"
    echo -e "\033[1;97;44m        Добро пожаловать в скрипт управления нодой Waku        \033[0m"
    echo -e "\033[1;30;42m==========================================================\033[0m"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Проверка и установка curl, если он отсутствует
if ! command -v curl &> /dev/null; then
    echo -e "\033[1;37;41mУстанавливаем curl...\033[0m"
    sudo apt update
    sudo apt install curl -y
fi

# Функция установки необходимых пакетов
function install_dependencies() {
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop \
        nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip
}

# Функция установки Docker и Docker Compose
function install_docker() {
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com | sh
    fi
    if ! command -v docker-compose &> /dev/null; then
    sudo apt update && sudo apt install -y docker-compose
    command -v docker-compose &> /dev/null && echo -e "\033[1;30;42mDocker Compose успешно установлен!\033[0m" || { echo -e "\033[1;31;40mОшибка установки.\033[0m"; exit 1; }

}

# Установка ноды Waku
function install_node() {
    install_dependencies
    install_docker

    cd $HOME
    git clone https://github.com/waku-org/nwaku-compose
    cd nwaku-compose
    cp .env.example .env

    echo -e "\033[0;36;43mВставьте ваш RPC Sepolia ETH:\033[0m"
    read RPC
    echo -e "\033[0;36;43mВставьте ваш приватный ключ от EVM кошелька, на котором есть Sepolia ETH:\033[0m"
    read PRIVATE_KEY
    echo -e "\033[0;36;43mУстановите пароль:\033[0m"
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
    docker-compose up -d

    echo -e "\033[1;30;42mОбновление завершено!\033[0m"
}

# Просмотр логов ноды
function view_logs() {
    echo -e "\033[1;97;44mПросмотр логов ноды Waku...\033[0m"
    cd $HOME/nwaku-compose && docker-compose logs -f
}

# Удаление ноды Waku
function remove_node() {
    echo -e "\033[1;97;44mУдаляем ноду Waku...\033[0m"
    cd $HOME/nwaku-compose
    docker-compose down
    cd $HOME
    rm -rf nwaku-compose
    rm -rf waku_node.sh
    echo -e "\033[1;30;42mНода успешно удалена!\033[0m"
}

# Главное меню
function show_menu() {
    show_logo
    echo -e "\033[0;36;43m1) 🚀 Установить ноду\033[0m"
    echo -e "\033[0;36;43m2) 🔄 Обновить ноду\033[0m"
    echo -e "\033[0;36;43m3) 📜 Просмотр логов\033[0m"
    echo -e "\033[0;36;43m4) 🗑️ Удалить ноду\033[0m"
    echo -e "\033[0;36;43m5) ❌ Выйти\033[0m"

    echo -e "\033[1;37;41mВыберите действие:\033[0m"
    read choice

    case $choice in
        1) install_node ;;
        2) update_node ;;
        3) view_logs ;;
        4) remove_node ;;
        5) echo -e "\033[1;30;42mВыход...\033[0m" && exit 0 ;;
        *) echo -e "\033[1;31;40mНеверный выбор! Попробуйте снова.\033[0m" && show_menu ;;
    esac
}

# Запуск меню
show_menu
