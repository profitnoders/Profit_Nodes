#!/bin/bash

# Цветовые коды для отображения сообщений
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Сброс цвета

# Функция для отображения логотипа
function show_logo() {
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${CYAN}          Добро пожаловать в скрипт управления нодой InitVerse          ${NC}"
    echo -e "${GREEN}==========================================================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Проверка и установка curl, если он отсутствует
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

# Функция установки зависимостей
function install_dependencies() {
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y wget
}

# Функция для установки ноды InitVerse
function install_node() {
    install_dependencies

    mkdir -p $HOME/initverse
    cd $HOME/initverse
    wget https://github.com/Project-InitVerse/ini-miner/releases/download/v1.0.0/iniminer-linux-x64
    chmod +x iniminer-linux-x64

    echo -e "${YELLOW}Введите адрес EVM кошелька:${NC}"
    read WALLET
    echo -e "${YELLOW}Задайте имя майнера:${NC}"
    read NODE_NAME

    # Создаем файл конфигурации .env
    echo "WALLET=$WALLET" > "$HOME/initverse/.env"
    echo "NODE_NAME=$NODE_NAME" >> "$HOME/initverse/.env"

    # Создаем системный сервис
    sudo bash -c "cat <<EOT > /etc/systemd/system/initverse.service
[Unit]
Description=InitVerse Miner Service
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$HOME/initverse
EnvironmentFile=$HOME/initverse/.env
ExecStart=/bin/bash -c 'source $HOME/initverse/.env && $HOME/initverse/iniminer-linux-x64 --pool stratum+tcp://${WALLET}.${NODE_NAME}@pool-core-testnet.inichain.com:32672 --cpu-devices 1 --cpu-devices 2'
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

    # Запуск сервиса
    sudo systemctl daemon-reload
    sudo systemctl enable initverse
    sudo systemctl start initverse

}


# Функция для просмотра логов
function view_logs() {
    sudo journalctl -fu initverse.service
}

# Функция для удаления ноды InitVerse
function remove_node() {

    # Остановка и удаление сервиса
    sudo systemctl stop initverse
    sudo systemctl disable initverse
    sudo rm /etc/systemd/system/initverse.service
    sudo systemctl daemon-reload

    # Удаление папки ноды
    if [ -d "$HOME/initverse" ]; then
        rm -rf $HOME/initverse
        echo -e "${GREEN}Нода InitVerse удалена.${NC}"
    else
        echo -e "${RED}Нода InitVerse не была установлена.${NC}"
    fi

}

# Главное меню
function show_menu() {
    show_logo
    echo -e "${CYAN}1) 🚀 Установить ноду${NC}"
    echo -e "${CYAN}2) 📜 Просмотр логов${NC}"
    echo -e "${CYAN}3) 🗑️ Удалить ноду${NC}"
    echo -e "${CYAN}4) ❌ Выйти${NC}"

    echo -e "${YELLOW}Выберите действие:${NC}"
    read choice

    case $choice in
        1) install_node ;;
        2) view_logs ;;
        3) remove_node ;;
        4) echo -e "${GREEN}Выход...${NC}" && exit 0 ;;
        *) echo -e "${RED}Попробуйте снова.${NC}" && show_menu ;;
    esac
}

# Запуск меню
show_menu
