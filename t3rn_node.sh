#!/bin/bash

# Определяем цвета для текста
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
    echo -e "${CYAN}       Добро пожаловать в скрипт управления нодой t3rn       ${NC}"
    echo -e "${GREEN}==========================================================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Проверка версии Ubuntu
function check_ubuntu_version() {
    UBUNTU_VERSION=$(lsb_release -rs)
    REQUIRED_VERSION=22.04

    if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
        echo -e "${RED}Для установки требуется Ubuntu версии 22.04 или выше.${NC}"
        exit 1
    fi
}

# Установка необходимых зависимостей
function install_dependencies() {
    echo -e "${BLUE}Устанавливаем необходимые пакеты...${NC}"
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y curl figlet jq build-essential gcc unzip wget lz4 bc
}

# Установка ноды t3rn
function install_node() {
    check_ubuntu_version
    install_dependencies

    echo -e "${BLUE}Скачиваем и устанавливаем последнюю версию ноды t3rn...${NC}"
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep 'tag_name' | cut -d\" -f4)
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/${LATEST_VERSION}/executor-linux-${LATEST_VERSION}.tar.gz"
    curl -L -o executor-linux-${LATEST_VERSION}.tar.gz $EXECUTOR_URL
    tar -xzvf executor-linux-${LATEST_VERSION}.tar.gz
    rm -rf executor-linux-${LATEST_VERSION}.tar.gz

    echo -e "${YELLOW}Введите ваш приватный ключ для ноды:${NC}"
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

    echo -e "${GREEN}Установка завершена!${NC}"
    echo -e "${YELLOW}Для проверки логов выполните:${NC} sudo journalctl -u t3rn -f"
}

# Обновление ноды t3rn
function update_node() {
    echo -e "${BLUE}Обновляем ноду t3rn до последней версии...${NC}"
    sudo systemctl stop t3rn
    rm -rf $HOME/executor/

    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep 'tag_name' | cut -d\" -f4)
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/${LATEST_VERSION}/executor-linux-${LATEST_VERSION}.tar.gz"
    curl -L -o executor-linux-${LATEST_VERSION}.tar.gz $EXECUTOR_URL
    tar -xzvf executor-linux-${LATEST_VERSION}.tar.gz
    rm -rf executor-linux-${LATEST_VERSION}.tar.gz

    sudo systemctl start t3rn
    echo -e "${GREEN}Обновление завершено!${NC}"
}

# Удаление ноды t3rn
function remove_node() {
    echo -e "${RED}Удаляем ноду t3rn...${NC}"
    sudo systemctl stop t3rn
    sudo systemctl disable t3rn
    sudo rm /etc/systemd/system/t3rn.service
    rm -rf $HOME/executor/
    echo -e "${GREEN}Нода успешно удалена!${NC}"
}

# Просмотр логов
function view_logs() {
    echo -e "${BLUE}Открываем логи ноды...${NC}"
    sudo journalctl -u t3rn -f
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
    read -r choice

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
