#!/bin/bash

# Цветовые коды для отображения текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Сброс цвета

# Функция для отображения логотипа
function show_logo() {
    echo -e "${GREEN}===============================${NC}"
    echo -e "${CYAN} Добро пожаловать в скрипт установки ноды Dria ${NC}"
    echo -e "${GREEN}===============================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция для установки зависимостей
function install_dependencies() {
    echo -e "${YELLOW}Обновляем систему и устанавливаем необходимые пакеты...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git make jq build-essential gcc unzip wget lz4 aria2 curl
}

# Установка ноды
function install_node() {
    echo -e "${BLUE}Начинаем установку ноды Dria...${NC}"
    install_dependencies

    ARCH=$(uname -m)
    if [[ "$ARCH" == "aarch64" ]]; then
        DOWNLOAD_URL="https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-arm64.zip"
    elif [[ "$ARCH" == "x86_64" ]]; then
        DOWNLOAD_URL="https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-amd64.zip"
    else
        echo -e "${RED}Неизвестная архитектура системы: $ARCH. Установка невозможна.${NC}"
        exit 1
    fi

    curl -L -o dkn-compute-node.zip $DOWNLOAD_URL
    unzip dkn-compute-node.zip -d dkn-compute-node
    cd dkn-compute-node || { echo -e "${RED}Не удалось войти в директорию установки. Прерывание.${NC}"; exit 1; }
    ./dkn-compute-launcher
}

# Создание и запуск сервиса
function create_and_start_service() {
    echo -e "${BLUE}Настраиваем системный сервис для ноды Dria...${NC}"
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo "~$USERNAME")

    sudo bash -c "cat <<EOT > /etc/systemd/system/dria.service
[Unit]
Description=Dria Compute Node Service
After=network.target

[Service]
User=$USERNAME
EnvironmentFile=$HOME_DIR/dkn-compute-node/.env
ExecStart=$HOME_DIR/dkn-compute-node/dkn-compute-launcher
WorkingDirectory=$HOME_DIR/dkn-compute-node/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

    sudo systemctl daemon-reload
    sudo systemctl enable dria
    sudo systemctl start dria
    echo -e "${GREEN}Сервис Dria запущен!${NC}"
}

# Обновление ноды
function update_node() {
    echo -e "${BLUE}Обновление ноды до последней версии...${NC}"
    sudo systemctl stop dria
    rm -rf $HOME/dkn-compute-node
    install_node
    create_and_start_service
    echo -e "${GREEN}Нода обновлена!${NC}"
}

# Изменение порта
function change_port() {
    echo -e "${YELLOW}Введите новый порт для ноды Dria:${NC}"
    read -r NEW_PORT
    sed -i "s|DKN_P2P_LISTEN_ADDR=/ip4/0.0.0.0/tcp/[0-9]*|DKN_P2P_LISTEN_ADDR=/ip4/0.0.0.0/tcp/$NEW_PORT|" "$HOME/dkn-compute-node/.env"
    sudo systemctl restart dria
    echo -e "${GREEN}Порт успешно изменен на $NEW_PORT.${NC}"
}

# Проверка логов
function check_logs() {
    echo -e "${BLUE}Просмотр логов ноды Dria...${NC}"
    sudo journalctl -u dria -f --no-hostname -o cat
}

# Удаление ноды
function remove_node() {
    echo -e "${BLUE}Удаление ноды Dria...${NC}"
    sudo systemctl stop dria
    sudo systemctl disable dria
    sudo rm /etc/systemd/system/dria.service
    rm -rf $HOME/dkn-compute-node
    sudo systemctl daemon-reload
    echo -e "${GREEN}Нода успешно удалена.${NC}"
}

# Меню выбора действий
function show_menu() {
    show_logo
    echo -e "${CYAN}1) 🚀 Установить ноду${NC}"
    echo -e "${CYAN}2) ✅ Запустить ноду${NC}"
    echo -e "${CYAN}3) 🔄 Обновить ноду${NC}"
    echo -e "${CYAN}4) 🔧 Изменить порт${NC}"
    echo -e "${CYAN}5) 📜 Просмотр логов${NC}"
    echo -e "${CYAN}6) 🗑️ Удалить ноду${NC}"
    echo -e "${CYAN}7) ❌ Выйти${NC}"
    echo -e "${YELLOW}Введите номер:${NC}"
    read -r choice

    case $choice in
        1) install_node ;;
        2) create_and_start_service ;;
        3) update_node ;;
        4) change_port ;;
        5) check_logs ;;
        6) remove_node ;;
        7) echo -e "${GREEN}Выход...${NC}" ;;
        *) echo -e "${RED}Неверный выбор. Попробуйте снова.${NC}" ;;
    esac
}

# Запуск меню
show_menu
