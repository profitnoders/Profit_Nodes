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
    echo -e "${CLR_INFO}       Добро пожаловать в скрипт управления нодой t3rn       ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Установка необходимых зависимостей
function install_dependencies() {
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y curl figlet jq build-essential gcc unzip wget lz4 bc
}

# Установка ноды t3rn
function install_node() {
    install_dependencies

    echo -e "${CLR_INFO}Скачиваем и устанавливаем последнюю версию ноды t3rn...${CLR_RESET}"
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep 'tag_name' | cut -d\" -f4)
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/${LATEST_VERSION}/executor-linux-${LATEST_VERSION}.tar.gz"
    curl -L -o executor-linux-${LATEST_VERSION}.tar.gz $EXECUTOR_URL
    tar -xzvf executor-linux-${LATEST_VERSION}.tar.gz
    rm -rf executor-linux-${LATEST_VERSION}.tar.gz

    echo -e "${CLR_WARNING}Введите ваш private key от EVM кошелька, на котором есть ETH Sepolia:${CLR_RESET}"
    read -r PRIVATE_KEY

    CONFIG_FILE="$HOME/executor/executor/bin/.t3rn"
    mkdir -p $HOME/executor/executor/bin/
    echo "NODE_ENV=testnet" > $CONFIG_FILE
    echo "LOG_LEVEL=debug" >> $CONFIG_FILE
    echo "LOG_PRETTY=false" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_ORDERS=true" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_CLAIMS=true" >> $CONFIG_FILE
    echo "PRIVATE_KEY_LOCAL=$PRIVATE_KEY" >> $CONFIG_FILE
    echo "ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l1rn'" >> $CONFIG_FILE
    echo "RPC_ENDPOINTS_BSSP='https://base-sepolia-rpc.publicnode.com'" >> $CONFIG_FILE

    # Создание systemd-сервиса
    sudo bash -c "cat <<EOT > /etc/systemd/system/t3rn.service
[Unit]
Description=t3rn Node Service
After=network.target

[Service]
EnvironmentFile=$HOME/executor/executor/bin/.t3rn
ExecStart=$HOME/executor/executor/bin/executor
WorkingDirectory=$HOME/executor/executor/bin/
Restart=on-failure
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOT"

    # Запуск сервиса
    sudo systemctl daemon-reload
    sudo systemctl enable t3rn
    sudo systemctl start t3rn

    echo -e "${CLR_SUCCESS}Установка завершена!${CLR_RESET}"
}

# Обновление ноды t3rn
function update_node() {    
    sudo systemctl stop t3rn
    cd && rm -rf executor/
    # Скачиваем новый бинарник
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep 'tag_name' | cut -d\" -f4)
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/${LATEST_VERSION}/executor-linux-${LATEST_VERSION}.tar.gz"
    curl -L -o executor-linux-${LATEST_VERSION}.tar.gz $EXECUTOR_URL
    tar -xzvf executor-linux-${LATEST_VERSION}.tar.gz
    rm -rf executor-linux-${LATEST_VERSION}.tar.gz

    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)
        
    CONFIG_FILE="$HOME_DIR/executor/executor/bin/.t3rn"
    echo "NODE_ENV=testnet" > $CONFIG_FILE
    echo "LOG_LEVEL=debug" >> $CONFIG_FILE
    echo "LOG_PRETTY=false" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_ORDERS=true" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_CLAIMS=true" >> $CONFIG_FILE
    echo "PRIVATE_KEY_LOCAL=" >> $CONFIG_FILE
    echo "ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l1rn'" >> $CONFIG_FILE
    echo "RPC_ENDPOINTS_BSSP='https://base-sepolia-rpc.publicnode.com'" >> $CONFIG_FILE

    echo -e "${YELLOW}Введите ваш приватный ключ от кошелька для ноды:${CLR_RESET}"
    read PRIVATE_KEY
    sed -i "s|PRIVATE_KEY_LOCAL=|PRIVATE_KEY_LOCAL=$PRIVATE_KEY|" $CONFIG_FILE
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-journald
    sudo systemctl start t3rn
    sleep 1

    echo -e "${CLR_SUCCESS}Обновление завершено!${CLR_RESET}"
}

# Удаление ноды t3rn
function remove_node() {
    echo -e "${CLR_ERROR}Удаляем ноду t3rn...${CLR_RESET}"
    sudo systemctl stop t3rn
    sudo systemctl disable t3rn
    sudo rm /etc/systemd/system/t3rn.service
    rm -rf $HOME/executor/
    echo -e "${CLR_SUCCESS}Нода успешно удалена!${CLR_RESET}"
}

# Просмотр логов
function view_logs() {
    echo -e "${CLR_INFO}Логи ноды t3rn...${CLR_RESET}"
    sudo journalctl -u t3rn -f
}

# Главное меню
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 🔄 Обновить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 📜 Просмотр логов${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 🗑️ Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}5) ❌ Выйти${CLR_RESET}"

    echo -e "${CLR_INFO}Выберите действие:${CLR_RESET}"
    read -r choice

    case $choice in
        1) install_node ;;
        2) update_node ;;
        3) view_logs ;;
        4) remove_node ;;
        5) echo -e "${CLR_SUCCESS}Выход...${CLR_RESET}" && exit 0 ;;
        *) echo -e "${CLR_ERROR}Неверный выбор! Попробуйте снова.${CLR_RESET}" && show_menu ;;
    esac
}

# Запуск меню
show_menu
