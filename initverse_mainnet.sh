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
    echo -e "${CLR_INFO}       Добро пожаловать в скрипт управления InitVerse Mainnet       ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}



# Функция установки зависимостей
function install_dependencies() {
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y wget

    # Проверка и установка curl, если его нет
    if ! command -v curl &> /dev/null; then
        sudo apt update
        sudo apt install curl -y
    fi
}

# Установка ноды InitVerse Mainnet
function install_node() {
    install_dependencies

    mkdir -p $HOME/initverse
    cd $HOME/initverse
    wget https://github.com/Project-InitVerse/ini-miner/releases/download/v1.0.0/iniminer-linux-x64
    chmod +x iniminer-linux-x64

    echo -e "${CLR_WARNING}Введите имя для майнера:${CLR_RESET}"
    read MAINER_NAME
    echo -e "${CLR_WARNING}Вставьте EVM-адрес кошелька:${CLR_RESET}"
    read WALLET

    # Создаем файл конфигурации .env
    echo "WALLET=$WALLET" > "$HOME/initverse/.env"
    echo "MAINER_NAME=$MAINER_NAME" >> "$HOME/initverse/.env"

    # Создаем системный сервис
    sudo bash -c "cat <<EOT > /etc/systemd/system/initverse.service
[Unit]
Description=InitVerse Mainnet Miner Service
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$HOME/initverse
EnvironmentFile=$HOME/initverse/.env
ExecStart=/bin/bash -c 'source $HOME/initverse/.env && $HOME/initverse/iniminer-linux-x64 --pool stratum+tcp://${WALLET}.${MAINER_NAME}@pool-c.yatespool.com:31189 --cpu-devices 1 --cpu-devices 2'
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

    # Запуск системного сервиса
    sudo systemctl daemon-reload
    sudo systemctl enable initverse
    sudo systemctl start initverse
    echo -e "${CLR_SUCCESS}Нода InitVerse в сети Mainnet установлена !${CLR_RESET}"
}


# Просмотр логов
function view_logs() {
    echo -e "${CLR_INFO}Логи InitVerse Mainnet...${CLR_RESET}"
    sudo journalctl -fu initverse.service
}

# Удаление ноды InitVerse Mainnet
function remove_node() {
    sudo systemctl stop initverse
    sudo systemctl disable initverse
    sudo rm /etc/systemd/system/initverse.service
    sudo systemctl daemon-reload

    # Удаление файлов ноды
    if [ -d "$HOME/initverse" ]; then
        rm -rf $HOME/initverse
        echo -e "${CLR_WARNING}Все файлы ноды InitVerse Mainnet удалены.${CLR_RESET}"
    fi
}

# Главное меню
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 📜 Просмотр логов${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 🗑️ Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}4) ❌ Выйти${CLR_RESET}"

    echo -e "${CLR_INFO}Выберите номер действия:${CLR_RESET}"
    read choice

    case $choice in
        1) install_node ;;
        2) view_logs ;;
        3) remove_node ;;
        4) echo -e "${CLR_ERROR}Выход...${CLR_RESET}" && exit 0 ;;
        *) echo -e "${CLR_WARNING}Неверный выбор. Попробуйте снова.${CLR_RESET}" && show_menu ;;
    esac
}

# Запуск меню
show_menu
