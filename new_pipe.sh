#!/bin/bash

# Цвета для оформления текста
CLR_INFO='\033[1;97;44m'
CLR_SUCCESS='\033[1;30;42m'
CLR_WARNING='\033[1;37;41m'
CLR_ERROR='\033[1;31;40m'
CLR_GREEN='\033[1;32m'
CLR_RESET='\033[0m'

# Функция отображения логотипа
function show_logo() {
    echo -e "${CLR_INFO}      Добро пожаловать в скрипт управления нодой Pipe Network      ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/main/logo_new.sh | bash
}

# Установка зависимостей
function install_dependencies() {
    echo -e "${CLR_INFO}▶ Обновляем систему и устанавливаем зависимости...${CLR_RESET}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl ufw
}

# Установка и настройка ноды
function install_node() {
    echo -e "${CLR_INFO}▶ Установка Pipe Node...${CLR_RESET}"
    sudo curl -L -o /usr/local/bin/pop https://dl.pipecdn.app/v0.2.8/pop
    sudo chmod +x /usr/local/bin/pop
    mkdir -p $HOME/pipe-node/download_cache

    echo -e "${CLR_INFO}▶ Открытие портов 80, 443, 8003 через UFW...${CLR_RESET}"
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 8003/tcp
    sudo ufw reload

    read -p "Введите ваш Solana кошелек (pubKey): " WALLET_KEY
    read -p "Введите объем RAM для ноды (в ГБ, например 4): " RAM
    read -p "Введите макс. объем диска (в ГБ, например 100): " DISK

    echo -e "${CLR_INFO}▶ Создание systemd-сервиса...${CLR_RESET}"
    sudo tee /etc/systemd/system/pipe-node.service > /dev/null <<EOF
[Unit]
Description=Pipe Network Node
After=network.target

[Service]
ExecStart=/usr/local/bin/pop --ram ${RAM} --max-disk ${DISK} --cache-dir $HOME/pipe-node/download_cache --pubKey ${WALLET_KEY} --enable-80-443
Restart=on-failure
User=$USER
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable pipe-node
    sudo systemctl start pipe-node

    echo -e "${CLR_SUCCESS}✅ Нода Pipe установлена и запущена через systemd!${CLR_RESET}"
    echo -e "${CLR_INFO}▶ Просмотр логов: sudo journalctl -u pipe-node -f${CLR_RESET}"
}

# Запуск ноды
function start_node() {
    echo -e "${CLR_INFO}▶ Запуск ноды Pipe...${CLR_RESET}"
    sudo systemctl restart pipe-node
    echo -e "${CLR_SUCCESS}✅ Нода запущена!${CLR_RESET}"
}

# Статус ноды
function check_status() {
    echo -e "${CLR_INFO}▶ Просмотр метрик...${CLR_RESET}"
    /usr/local/bin/pop --status
}

# Проверка поинтов
function check_points() {
    echo -e "${CLR_INFO}▶ Заработанные поинты...${CLR_RESET}"
    /usr/local/bin/pop --points
}

# Регистрация по реф. коду
function signup_referral() {
    read -p "Введите реферальный код: " REF_CODE
    echo -e "${CLR_INFO}▶ Регистрация...${CLR_RESET}"
    /usr/local/bin/pop --signup-by-referral-route "$REF_CODE"
}

# Удаление ноды
function remove_node() {
    read -p "⚠ Удалить ноду Pipe? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" ]]; then
        echo -e "${CLR_WARNING}▶ Остановка и удаление...${CLR_RESET}"
        sudo systemctl stop pipe-node
        sudo systemctl disable pipe-node
        sudo rm -f /etc/systemd/system/pipe-node.service
        sudo systemctl daemon-reload
        sudo rm -f /usr/local/bin/pop
        rm -rf $HOME/pipe-node
        echo -e "${CLR_SUCCESS}✅ Нода полностью удалена.${CLR_RESET}"
    else
        echo -e "${CLR_INFO}▶ Отмена удаления.${CLR_RESET}"
    fi
}

# Меню
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) ▶  Запустить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 📊 Статус ноды${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 💰 Проверить поинты${CLR_RESET}"
    echo -e "${CLR_GREEN}5) 🔗 Реферальная регистрация${CLR_RESET}"
    echo -e "${CLR_GREEN}6) 🗑️  Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}7) ❌ Выход${CLR_RESET}"
    echo -ne "${CLR_INFO}▶ Ваш выбор: ${CLR_RESET}"
    read -r choice

    case $choice in
        1) install_dependencies && install_node ;;
        2) start_node ;;
        3) check_status ;;
        4) check_points ;;
        5) signup_referral ;;
        6) remove_node ;;
        7) echo -e "${CLR_ERROR}Выход...${CLR_RESET}" ;;
        *) echo -e "${CLR_WARNING}Неверный ввод. Повторите.${CLR_RESET}" ;;
    esac
}

# Запуск
show_menu
