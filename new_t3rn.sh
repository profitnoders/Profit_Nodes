#!/bin/bash

# Цвета оформления
CLR_SUCCESS='\033[1;32m'  # Зеленый
CLR_INFO='\033[1;34m'  # Синий
CLR_WARNING='\033[1;33m'  # Желтый
CLR_ERROR='\033[1;31m'  # Красный
CLR_RESET='\033[0m'  # Сброс цвета

# Функция вывода логотипа
function show_logo() {
    echo -e "${CLR_INFO}     Добро пожаловать в скрипт управления нодой t3rn v.2    ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция установки ноды
function install_node() {
    echo -e "${CLR_INFO}▶ Обновление системы и установка зависимостей...${CLR_RESET}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y screen wget curl tar

    echo -e "${CLR_INFO}▶ Создание директории t3rn...${CLR_RESET}"
    mkdir -p $HOME/t3rn && cd $HOME/t3rn

    echo -e "${CLR_INFO}▶ Загрузка последней версии executor...${CLR_RESET}"
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    wget https://github.com/t3rn/executor-release/releases/download/${LATEST_VERSION}/executor-linux-${LATEST_VERSION}.tar.gz

    echo -e "${CLR_INFO}▶ Распаковка executor...${CLR_RESET}"
    tar -xzf executor-linux-*.tar.gz
    cd executor/executor/bin

    echo -e "${CLR_INFO}▶ Настройка окружения...${CLR_RESET}"
    echo "export ENVIRONMENT=testnet" >> ~/.bashrc
    echo "export LOG_LEVEL=debug" >> ~/.bashrc
    echo "export LOG_PRETTY=false" >> ~/.bashrc
    echo "export EXECUTOR_PROCESS_BIDS_ENABLED=true" >> ~/.bashrc
    echo "export EXECUTOR_PROCESS_ORDERS_ENABLED=true" >> ~/.bashrc
    echo "export EXECUTOR_PROCESS_CLAIMS_ENABLED=true" >> ~/.bashrc
    echo "export EXECUTOR_MAX_L3_GAS_PRICE=100" >> ~/.bashrc

    read -p "Введите ваш PRIVATE_KEY_LOCAL: " private_key
    echo "export PRIVATE_KEY_LOCAL=${private_key}" >> ~/.bashrc

    echo "Введите список сетей через запятую (по умолчанию: arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn):"
    read -p "ENABLED_NETWORKS: " enabled_networks
    enabled_networks=${enabled_networks:-"arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn"}
    echo "export ENABLED_NETWORKS='${enabled_networks}'" >> ~/.bashrc

    echo "Введите RPC-эндпоинты в формате JSON или нажмите Enter для значений по умолчанию:"
    read -p "RPC_ENDPOINTS: " rpc_endpoints
    rpc_endpoints=${rpc_endpoints:-'{
        "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
        "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
        "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
        "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
        "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"]
    }'}
    echo "export RPC_ENDPOINTS='${rpc_endpoints}'" >> ~/.bashrc
    echo "export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true" >> ~/.bashrc
    source ~/.bashrc

    echo -e "${CLR_SUCCESS}✅ Установка завершена! Теперь вы можете запустить ноду.${CLR_RESET}"
}

# Функция запуска ноды
function start_node() {
    echo -e "${CLR_INFO}▶ Запуск t3rn-executor в screen-сессии...${CLR_RESET}"
    screen -dmS t3rn-executor bash -c "$HOME/t3rn/executor/executor/bin/executor"
    echo -e "${CLR_SUCCESS}✅ Нода запущена в screen-сессии 't3rn-executor'!${CLR_RESET}"
    echo -e "${CLR_INFO}▶ Чтобы подключиться, используйте: screen -r t3rn-executor${CLR_RESET}"
    echo -e "${CLR_INFO}▶ Чтобы отсоединиться, нажмите: Ctrl + A, затем D${CLR_RESET}"
}

# Функция перезапуска ноды
function restart_node() {
    echo -e "${CLR_INFO}▶ Перезапуск t3rn-executor...${CLR_RESET}"
    screen -S t3rn-executor -X quit
    start_node
    echo -e "${CLR_SUCCESS}✅ Нода успешно перезапущена!${CLR_RESET}"
}

# Функция удаления ноды (с подтверждением)
function remove_node() {
    echo -e "${CLR_WARNING}⚠ Вы уверены, что хотите удалить ноду t3rn-executor? (y/n)${CLR_RESET}"
    read -p "Введите y для подтверждения или n для отмены: " confirmation
    if [[ $confirmation == "y" || $confirmation == "Y" ]]; then
        echo -e "${CLR_INFO}▶ Остановка и удаление ноды...${CLR_RESET}"
        screen -S t3rn-executor -X quit
        rm -rf $HOME/t3rn
        sed -i '/EXECUTOR_PROCESS_BIDS_ENABLED/d' ~/.bashrc
        sed -i '/EXECUTOR_PROCESS_ORDERS_ENABLED/d' ~/.bashrc
        sed -i '/EXECUTOR_PROCESS_CLAIMS_ENABLED/d' ~/.bashrc
        sed -i '/EXECUTOR_MAX_L3_GAS_PRICE/d' ~/.bashrc
        sed -i '/PRIVATE_KEY_LOCAL/d' ~/.bashrc
        sed -i '/ENABLED_NETWORKS/d' ~/.bashrc
        sed -i '/RPC_ENDPOINTS/d' ~/.bashrc
        sed -i '/EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API/d' ~/.bashrc
        source ~/.bashrc
        echo -e "${CLR_SUCCESS}✅ Нода успешно удалена.${CLR_RESET}"
    else
        echo -e "${CLR_INFO}▶ Удаление отменено.${CLR_RESET}"
    fi
}

# Функция вывода меню
function show_menu() {
    show_logo
    echo -e "${CLR_INFO}Выберите действие:${CLR_RESET}"
    echo -e "${CLR_SUCCESS}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}2) ▶ Запустить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}3) 🔄 Перезапустить ноду${CLR_RESET}"
    echo -e "${CLR_WARNING}4) 🗑 Удалить ноду${CLR_RESET}"
    echo -e "${CLR_ERROR}5) ❌ Выйти${CLR_RESET}"
    
    read -p "Введите номер действия: " choice

    case $choice in
        1) install_node ;;
        2) start_node ;;
        3) restart_node ;;
        4) remove_node ;;
        5) echo -e "${CLR_ERROR}Выход...${CLR_RESET}" ;;
        *) echo -e "${CLR_WARNING}Неверный ввод, попробуйте снова.${CLR_RESET}" ;;
    esac
}

# Запуск меню
show_menu
