#!/bin/bash

# Оформление текста: цвета и фоны
CLR_INFO='\033[1;97;44m'  # Белый текст на синем фоне
CLR_SUCCESS='\033[1;30;42m'  # Зеленый текст на черном фоне
CLR_WARNING='\033[1;37;41m'  # Белый текст на красном фоне
CLR_ERROR='\033[1;31;40m'  # Красный текст на черном фоне
CLR_RESET='\033[0m'  # Сброс форматирования
CLR_GREEN='\033[0;32m' #Зеленый текст

# Функция для отображения логотипа
function show_logo() {
    echo -e "${CLR_SUCCESS} Добро пожаловать в скрипт установки ноды Dria ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция для установки зависимостей
function install_dependencies() {
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git make jq build-essential gcc unzip wget lz4 aria2 curl
}

# Установка ноды
function install_node() {
    echo -e "${CLR_INFO}Начинаем установку ноды Dria...${CLR_RESET}"
    install_dependencies

    # Обновление и установка зависимостей
    sudo apt update && sudo apt-get upgrade -y
    sudo apt install git make jq build-essential gcc unzip wget lz4 aria2 -y

    # Проверка архитектуры системы
    ARCH=$(uname -m)

    if [[ "$ARCH" == "aarch64" || "$ARCH" == "x86_64" ]]; then
        DOWNLOAD_URL="https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-amd64.zip"
        curl -L -o dkn-compute-node.zip "$DOWNLOAD_URL"
    else
        echo -e "\033[1;31;40mОшибка поддержки архитектуры $ARCH\033[0m"
        exit 1
    fi

    # Распаковываем ZIP-файл и переходим в папку
    unzip dkn-compute-node.zip
    cd dkn-compute-node

    # Запускаем приложение для ввода данных
    ./dkn-compute-launcher
}

# Создание и запуск сервиса
function create_and_start_service() {
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
    echo -e "${CLR_SUCCESS}Сервис Dria запущен!${CLR_RESET}"
}

# Обновление ноды
function update_node() {
    echo -e "${CLR_INFO}Обновление ноды до последней версии...${CLR_RESET}"
    sudo systemctl stop dria
    rm -rf $HOME/dkn-compute-node
    install_node
    create_and_start_service
    echo -e "${CLR_SUCCESS}Нода обновлена!${CLR_RESET}"
}

# Проверка логов
function check_logs() {
    echo -e "${CLR_INFO}Логи ноды Dria...${CLR_RESET}"
    sudo journalctl -u dria -f --no-hostname -o cat
}

# Удаление ноды
function remove_node() {
    sudo systemctl stop dria
    sudo systemctl disable dria
    sudo rm /etc/systemd/system/dria.service
    rm -rf $HOME/dkn-compute-node
    sudo systemctl daemon-reload
    echo -e "${CLR_GREEN}Нода успешно удалена.${CLR_RESET}"
}

# Меню выбора действий
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) ✅ Запустить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 🔄 Обновить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 📜 Просмотр логов${CLR_RESET}"
    echo -e "${CLR_GREEN}5) 🗑️ Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}6) ❌ Выйти${CLR_RESET}"
    echo -e "${CLR_INFO}Введите номер:${CLR_RESET}"
    read -r choice

    case $choice in
        1) install_node ;;
        2) create_and_start_service ;;
        3) update_node ;;
        4) check_logs ;;
        5) remove_node ;;
        6) echo -e "${CLR_ERROR}Выход...${CLR_RESET}" ;;
        *) echo -e "${CLR_WARNING}Неверный выбор. Попробуйте снова.${CLR_RESET}" ;;
    esac
}

# Запуск меню
show_menu
