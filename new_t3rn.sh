#!/bin/bash

# Цвета оформления
CLR_SUCCESS='\033[1;32m'  
CLR_INFO='\033[1;34m'  
CLR_WARNING='\033[1;33m'  
CLR_ERROR='\033[1;31m'  
CLR_RESET='\033[0m'  

# Функция вывода логотипа
function show_logo() {
    echo -e "${CLR_INFO}     Добро пожаловать в скрипт управления нодой t3rn v.2    ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

function install_node() {
    show_logo
    echo -e "${CLR_INFO}▶ Обновление системы и установка зависимостей...${CLR_RESET}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y wget curl tar systemd

    echo -e "${CLR_INFO}▶ Создание директории t3rn...${CLR_RESET}"
    mkdir -p $HOME/t3rn && cd $HOME/t3rn

    echo -e "${CLR_INFO}▶ Загрузка executor...${CLR_RESET}"
    # wget https://github.com/t3rn/executor-release/releases/download/v0.57.0/executor-linux-v0.57.0.tar.gz
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    wget https://github.com/t3rn/executor-release/releases/download/${LATEST_VERSION}/executor-linux-${LATEST_VERSION}.tar.gz
    
    echo -e "${CLR_INFO}▶ Распаковка executor...${CLR_RESET}"
    tar -xzf executor-linux-*.tar.gz
    # tar -xzf executor-linux-v0.57.0.tar.gz
    cd executor/executor/bin

    echo -e "${CLR_INFO}▶ Создание конфигурационного файла .t3rn...${CLR_RESET}"
    CONFIG_FILE="$HOME/t3rn/executor/executor/bin/.t3rn"

    cat <<EOF > $CONFIG_FILE
ENVIRONMENT=testnet
LOG_LEVEL=info
LOG_PRETTY=false

EXECUTOR_PROCESS_BIDS_ENABLED=true
EXECUTOR_PROCESS_ORDERS_ENABLED=true
EXECUTOR_PROCESS_CLAIMS_ENABLED=true
EXECUTOR_MAX_L3_GAS_PRICE=100
NETWORKS_DISABLED='blast-sepolia'
ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn,unichain-sepolia'

# Однострочный JSON — обязательно!
RPC_ENDPOINTS='{
    "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
    "arbt": ["https://arbitrum-sepolia.drpc.org/", "https://sepolia-rollup.arbitrum.io/rpc"],
    "bast": ["https://base-sepolia-rpc.publicnode.com/", "https://base-sepolia.drpc.org/"],
    "opst": ["https://endpoints.omniatech.io/v1/op/sepolia/public", "https://sepolia.optimism.io/", "https://optimism-sepolia.drpc.org/"],
    "unit": ["https://unichain-sepolia.drpc.org/", "https://sepolia.unichain.org/"]
}'

EXECUTOR_PROCESS_ORDERS_API_ENABLED=false
EXECUTOR_ENABLE_BATCH_BIDDING=true
EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
EOF

    echo -e "${CLR_INFO}▶ Введите ваш PRIVATE_KEY_LOCAL:${CLR_RESET}"
    read PRIVATE_KEY
    echo "PRIVATE_KEY_LOCAL=$PRIVATE_KEY" >> $CONFIG_FILE

    echo -e "${CLR_INFO}▶ Создание systemd-сервиса t3rn...${CLR_RESET}"
    sudo bash -c "cat <<EOT > /etc/systemd/system/t3rn.service
[Unit]
Description=t3rn Executor Node
After=network.target

[Service]
EnvironmentFile=$CONFIG_FILE
ExecStart=$HOME/t3rn/executor/executor/bin/executor
WorkingDirectory=$HOME/t3rn/executor/executor/bin/
Restart=on-failure
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOT"

    echo -e "${CLR_INFO}▶ Активация systemd-сервиса...${CLR_RESET}"
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable t3rn

    echo -e "${CLR_SUCCESS}✅ Установка завершена! Запусти ноду командой: sudo systemctl start t3rn${CLR_RESET}"
}



# Функция запуска ноды
function start_node() {
    echo -e "${CLR_INFO}▶ Запуск t3rn-executor через systemd...${CLR_RESET}"
    sudo systemctl start t3rn

    # Проверяем, успешно ли запущена нода
    sleep 2
    if systemctl is-active --quiet t3rn; then
        echo -e "${CLR_SUCCESS}✅ Нода успешно запущена!${CLR_RESET}"
        echo -e "${CLR_INFO}▶ Логи ноды: sudo journalctl -fu t3rn${CLR_RESET}"
    else
        echo -e "${CLR_ERROR}❌ Ошибка запуска ноды! Проверьте конфигурацию и попробуйте вручную.${CLR_RESET}"
    fi
}

# Функция перезапуска ноды
function restart_node() {
    echo -e "${CLR_INFO}▶ Перезапуск t3rn-executor...${CLR_RESET}"
    sudo systemctl restart t3rn
    echo -e "${CLR_SUCCESS}✅ Нода перезапущена!${CLR_RESET}"
}

# Функция вывода логов ноды
function logs_node() {
    echo -e "${CLR_INFO}▶ Логи ноды t3rn-executor...${CLR_RESET}"
    sudo journalctl -fu t3rn
}

# Функция удаления ноды (с подтверждением)
function remove_node() {
    echo -e "${CLR_WARNING}⚠ Вы уверены, что хотите удалить ноду t3rn? (y/n)${CLR_RESET}"
    read -p "Введите y для удаления: " confirm
    if [[ "$confirm" == "y" ]]; then
        echo -e "${CLR_INFO}▶ Остановка и удаление ноды...${CLR_RESET}"
        sudo systemctl stop t3rn
        sudo systemctl disable t3rn
        sudo rm -rf /etc/systemd/system/t3rn.service
        sudo systemctl daemon-reload
        rm -rf $HOME/t3rn
        rm new_t3rn.sh
        echo -e "${CLR_SUCCESS}✅ Нода успешно удалена.${CLR_RESET}"
    else
        echo -e "${CLR_INFO}▶ Отмена удаления.${CLR_RESET}"
    fi
}

# Функция вывода меню
function show_menu() {
    show_logo
    echo -e "${CLR_INFO}Выберите действие:${CLR_RESET}"
    echo -e "${CLR_SUCCESS}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}2)  ▶ Запустить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}3) 🔄 Перезапустить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}4) 📜 Показать логи ноды${CLR_RESET}"
    echo -e "${CLR_WARNING}5)  🗑 Удалить ноду${CLR_RESET}"
    echo -e "${CLR_ERROR}6) ❌ Выйти${CLR_RESET}"
    
    read -p "Введите номер действия: " choice

    case $choice in
        1) install_node ;;
        2) start_node ;;
        3) restart_node ;;
        4) logs_node ;;
        5) remove_node ;;
        6) echo -e "${CLR_ERROR}Выход...${CLR_RESET}"; exit 0 ;;
        *) echo -e "${CLR_WARNING}Неверный ввод, попробуйте снова.${CLR_RESET}" ;;
    esac
}

# Запуск меню
show_menu
