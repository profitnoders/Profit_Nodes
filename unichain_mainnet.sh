#!/bin/bash

# Цвета
CLR_SUCCESS='\033[1;32m'
CLR_INFO='\033[1;34m'
CLR_WARNING='\033[1;33m'
CLR_ERROR='\033[1;31m'
CLR_RESET='\033[0m'

NODE_DIR="$HOME/unichain-node"
function show_logo() {
    echo -e "${CLR_INFO}     Добро пожаловать в скрипт управления нодой Unichain mainnet     ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

function install_node() {
    sudo apt update && sudo apt upgrade -y
    echo -e "${CLR_INFO}▶ Установка Docker и Docker Compose...${CLR_RESET}"
    sudo apt update && sudo apt install docker.io -y
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    echo -e "${CLR_INFO}▶ Клонирование репозитория Unichain...${CLR_RESET}"
    git clone https://github.com/Uniswap/unichain-node $NODE_DIR

    echo -e "${CLR_INFO}▶ Активируем конфигурацию mainnet в docker-compose.yml...${CLR_RESET}"
    sed -i 's|# \s*\.env\.mainnet|        - .env.mainnet|' "$NODE_DIR/docker-compose.yml"
    echo -e "${CLR_SUCCESS}✅ Установка завершена.${CLR_RESET}"
}

function start_node() {
    echo -e "${CLR_INFO}▶ Запуск ноды...${CLR_RESET}"
    docker-compose -f "$NODE_DIR/docker-compose.yml" up -d
    echo -e "${CLR_SUCCESS}✅ Нода запущена.${CLR_RESET}"
}

function restart_node() {
    echo -e "${CLR_INFO}▶ Перезапуск ноды...${CLR_RESET}"
    docker-compose -f "$NODE_DIR/docker-compose.yml" down
    docker-compose -f "$NODE_DIR/docker-compose.yml" up -d
    echo -e "${CLR_SUCCESS}✅ Нода перезапущена.${CLR_RESET}"
}

function change_ports() {
    echo -e "${CLR_INFO}▶ Изменение портов для предотвращения конфликта...${CLR_RESET}"
    sed -i 's|30303:30303|31313:31313|' "$NODE_DIR/docker-compose.yml"
    sed -i 's|8545:8545|8647:8647|' "$NODE_DIR/docker-compose.yml"
    sed -i 's|8546:8546|8646:8646|' "$NODE_DIR/docker-compose.yml"
    sed -i 's|8551|8651|' "$NODE_DIR/.env.mainnet"
    sed -i 's|9222:9222|9332:9332|' "$NODE_DIR/docker-compose.yml"
    sed -i 's|9545:9545|9645:9645|' "$NODE_DIR/docker-compose.yml"
    echo -e "${CLR_SUCCESS}✅ Порты успешно изменены.${CLR_RESET}"
}

function logs_node() {
    echo -e "${CLR_INFO}▶ Просмотр логов...${CLR_RESET}"
    docker-compose -f "$NODE_DIR/docker-compose.yml" logs -f
}

function remove_node() {
    echo -e "${CLR_WARNING}⚠ Вы уверены, что хотите удалить ноду Unichain? (y/n)${CLR_RESET}"
    read -p "Ваш выбор: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        docker-compose -f "$NODE_DIR/docker-compose.yml" down -v
        rm -rf "$NODE_DIR"
        rm unichain_mainnet.sh
        echo -e "${CLR_SUCCESS}✅ Нода полностью удалена.${CLR_RESET}"
    else
        echo -e "${CLR_INFO}Удаление отменено.${CLR_RESET}"
    fi
}

function show_menu() {
    show_logo
    echo -e "${CLR_INFO}Выберите действие:${CLR_RESET}"
    echo -e "${CLR_SUCCESS}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}2) ▶ Запустить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}3) 🔄 Перезапустить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}4) 🛠 Изменить порты${CLR_RESET}"
    echo -e "${CLR_SUCCESS}5) 📜 Логи ноды${CLR_RESET}"
    echo -e "${CLR_WARNING}6) 🗑 Удалить ноду${CLR_RESET}"
    echo -e "${CLR_ERROR}7) ❌ Выход${CLR_RESET}"
    read -p "Введите номер действия: " choice
    case $choice in
        1) install_node ;;
        2) start_node ;;
        3) restart_node ;;
        4) change_ports ;;
        5) logs_node ;;
        6) remove_node ;;
        7) echo -e "${CLR_ERROR}Выход...${CLR_RESET}" && exit 0 ;;
        *) echo -e "${CLR_WARNING}Неверный выбор.${CLR_RESET}" ;;
    esac
}


show_menu

