#!/bin/bash

# Цветовые коды для отображения информации
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Сброс цвета

# Функция отображения логотипа
function show_logo() {
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${CYAN}       Добро пожаловать в скрипт управления InitVerse Mainnet       ${NC}"
    echo -e "${GREEN}==========================================================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Проверка и установка curl, если его нет
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

# Установка ноды InitVerse Mainnet
function install_node() {
    install_dependencies

    echo -e "${BLUE}Создаем директорию для ноды${NC}"
    mkdir -p $HOME/initverse
    cd $HOME/initverse
    wget https://github.com/Project-InitVerse/ini-miner/releases/download/v1.0.0/iniminer-linux-x64
    chmod +x iniminer-linux-x64

    echo -e "${YELLOW}Вставьте адрес вашего EVM кошелька:${NC}"
    read WALLET
    echo -e "${YELLOW}Введите имя для майнера:${NC}"
    read NODE_NAME

    # Создаем файл конфигурации .env
    echo "WALLET=$WALLET" > "$HOME/initverse/.env"
    echo "NODE_NAME=$NODE_NAME" >> "$HOME/initverse/.env"

    # Создаем системный сервис
    sudo bash -c "cat <<EOT > /etc/systemd/system/initverse.service
[Unit]
Description=InitVerse Mainnet Miner Service
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$HOME/initverse
EnvironmentFile=$HOME/initverse/.env
ExecStart=/bin/bash -c 'source $HOME/initverse/.env && $HOME/initverse/iniminer-linux-x64 --pool stratum+tcp://${WALLET}.${NODE_NAME}@pool-a.yatespool.com:31588 --cpu-devices 1 --cpu-devices 2'
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

    # Запуск системного сервиса
    sudo systemctl daemon-reload
    sudo systemctl enable initverse
    sudo systemctl start initverse
    echo -e "${GREEN}Нода InitVerse в сети Mainnet установлена !${NC}"
}


# Просмотр логов
function view_logs() {
    echo -e "${BLUE}Логи InitVerse Mainnet...${NC}"
    sudo journalctl -fu initverse.service
}

# Удаление ноды InitVerse Mainnet
function remove_node() {
    echo -e "${BLUE}Удаление ноды InitVerse Mainnet...${NC}"

    # Остановка и удаление сервиса
    sudo systemctl stop initverse
    sudo systemctl disable initverse
    sudo rm /etc/systemd/system/initverse.service
    sudo systemctl daemon-reload

    # Удаление файлов ноды
    if [ -d "$HOME/initverse" ]; then
        rm -rf $HOME/initverse
        echo -e "${GREEN}Все файлы ноды InitVerse Mainnet удалены.${NC}"
    fi
}

# Главное меню
function show_menu() {
    show_logo
    echo -e "${CYAN}1) 🚀 Установить ноду${NC}"
    echo -e "${CYAN}2) 📜 Просмотр логов${NC}"
    echo -e "${CYAN}3) 🗑️ Удалить ноду${NC}"
    echo -e "${CYAN}4) ❌ Выйти${NC}"

    echo -e "${YELLOW}Выберите номер действия:${NC}"
    read choice

    case $choice in
        1) install_node ;;
        2) view_logs ;;
        3) remove_node ;;
        4) echo -e "${GREEN}Выход...${NC}" && exit 0 ;;
        *) echo -e "${RED}Неверный выбор. Попробуйте снова.${NC}" && show_menu ;;
    esac
}

# Запуск меню
show_menu
