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
    sed -i 's|^[[:space:]]*#\s*- .env\.mainnet|      - .env.mainnet|' "$NODE_DIR/docker-compose.yml"

    read -rp "Введите новый URL для ETH Mainnet RPC (Execution endpoint): " new_eth_rpc
    read -rp "Введите новый URL для ETH Mainnet Beacon RPC (Consensus endpoint): " new_beacon_rpc
    
    # Экранируем слеши в переменных для sed
    escaped_eth_rpc=$(printf '%s\n' "$new_eth_rpc" | sed 's/[\/&]/\\&/g')
    escaped_beacon_rpc=$(printf '%s\n' "$new_beacon_rpc" | sed 's/[\/&]/\\&/g')
    
    sed -i "s|^OP_NODE_L1_ETH_RPC=.*|OP_NODE_L1_ETH_RPC=$escaped_eth_rpc|" ~/unichain-node/.env.mainnet
    sed -i "s|^OP_NODE_L1_BEACON=.*|OP_NODE_L1_BEACON=$escaped_beacon_rpc|" ~/unichain-node/.env.mainnet

    docker-compose -f "$NODE_DIR/docker-compose.yml" up -d
    echo -e "${CLR_SUCCESS}✅ Установка завершена. Нода запущена!${CLR_RESET}"
}

function logs_node() {
    echo -e "${CLR_INFO}▶ Просмотр логов...${CLR_RESET}"
    docker-compose -f "$NODE_DIR/docker-compose.yml" logs --tail 100
}

function remove_node() {
    echo -e "${CLR_WARNING}⚠ Вы уверены, что хотите удалить ноду Unichain? (y/n)${CLR_RESET}"
    read -p "Ваш выбор: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        docker-compose -f "$NODE_DIR/docker-compose.yml" down -v
        rm -rf "$NODE_DIR"
        rm unichain_sub.sh
        echo -e "${CLR_SUCCESS}✅ Нода полностью удалена.${CLR_RESET}"
    else
        echo -e "${CLR_INFO}Удаление отменено.${CLR_RESET}"
    fi
}

function show_nodekey() {
    cat ~/unichain-node/geth-data/geth/nodekey; echo
    echo -e "${CLR_SUCCESS}Запишите его себе в заметки${CLR_RESET}"
}

function show_menu() {
    show_logo
    echo -e "${CLR_INFO}Выберите действие:${CLR_RESET}"
    echo -e "${CLR_SUCCESS}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}2) 📜 Логи ноды${CLR_RESET}"
    echo -e "${CLR_SUCCESS}3) 🔑 Показать nodekey${CLR_RESET}"
    echo -e "${CLR_WARNING}4)  🗑 Удалить ноду${CLR_RESET}"
    echo -e "${CLR_ERROR}5) ❌ Выход${CLR_RESET}"
    read -p "Введите номер действия: " choice
    case $choice in
        1) install_node ;;
        2) logs_node ;;
        3) show_nodekey ;;
        4) remove_node ;;
        5) echo -e "${CLR_ERROR}Выход...${CLR_RESET}" && exit 0 ;;
        *) echo -e "${CLR_WARNING}Неверный выбор.${CLR_RESET}" ;;
    esac
}


show_menu
