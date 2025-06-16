#!/bin/bash


CLR_SUCCESS='\033[1;32m'
CLR_INFO='\033[1;34m'
CLR_WARNING='\033[1;33m'
CLR_ERROR='\033[1;31m'
CLR_RESET='\033[0m' # No Color

function show_logo() {
    echo -e "${CLR_INFO}     Добро пожаловать в скрипт установки ноды Cysic     ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

function install_node() {
    echo -e "${CLR_INFO}Введите адрес вашего EVM-кошелька:${CLR_RESET}"
    read -r EVM_ADDRESS

    if [[ -z "$EVM_ADDRESS" ]]; then
        echo -e "${CLR_ERROR}Ошибка: адрес EVM-кошелька не может быть пустым.${CLR_RESET}"
        exit 1
    fi

    echo -e "${CLR_WARNING}Начинается установка ноды Cysic с адресом: ${EVM_ADDRESS}${CLR_RESET}"
    curl -L https://github.com/cysic-labs/cysic-phase3/releases/download/v1.0.0/setup_linux.sh > ~/setup_linux.sh && bash ~/setup_linux.sh "$EVM_ADDRESS"

    if [[ $? -eq 0 ]]; then
        echo -e "${CLR_SUCCESS}Установка завершена успешно!${CLR_RESET}"
    else
        echo -e "${CLR_ERROR}Установка завершилась с ошибкой.${CLR_RESET}"
        exit 1
    fi

    echo -e "${CLR_INFO}Создание systemd-сервиса...${CLR_RESET}"

    sudo tee /etc/systemd/system/cysic.service > /dev/null <<EOF
[Unit]
Description=Cysic Verifier Node
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/cysic-verifier
ExecStart=/bin/bash $HOME/cysic-verifier/start.sh
Restart=always
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable cysic
    sudo systemctl start cysic

    echo -e "${CLR_SUCCESS}✅ Cysic-нода успешно запущена как systemd-сервис.${CLR_RESET}"
    echo -e "${CLR_INFO}Статус: sudo systemctl status cysic${CLR_RESET}"

}

function restart_node() {
    if systemctl list-units --type=service --all | grep -q cysic.service; then
        sudo systemctl restart cysic
        echo -e "${CLR_SUCCESS}Нода Cysic перезапущена.${CLR_RESET}"
    else
        echo -e "${CLR_ERROR}Служба Cysic не найдена. Установите ноду сначала.${CLR_RESET}"
    fi
}

function view_logs() {
    journalctl -u cysic -f
}

function remove_node() {
    echo -e "${CLR_WARNING}Удаление ноды Cysic...${CLR_RESET}"

    if [ -d "$HOME/cysic-verifier" ]; then
        rm -rf "$HOME/cysic-verifier"
        echo -e "${CLR_SUCCESS}Директория ноды Cysic успешно удалена.${CLR_RESET}"
    else
        echo -e "${CLR_WARNING}Директория ноды Cysic не найдена.${CLR_RESET}"
    fi

    if systemctl list-units --type=service --all | grep -q cysic.service; then
        sudo systemctl stop cysic
        sudo systemctl disable cysic
        sudo rm -f /etc/systemd/system/cysic.service
        sudo systemctl daemon-reload
        echo -e "${CLR_SUCCESS}Служба Cysic успешно удалена.${CLR_RESET}"
    else
        echo -e "${CLR_WARNING}Служба Cysic не найдена или уже удалена.${CLR_RESET}"
    fi

    echo -e "${CLR_SUCCESS}Нода Cysic успешно удалена!${CLR_RESET}"
}

function show_menu() {
    show_logo
    echo -e "${CLR_INFO}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_INFO}2) 🔁 Перезапустить ноду${CLR_RESET}"
    echo -e "${CLR_INFO}3) 📄 Просмотреть логи ноды${CLR_RESET}"
    echo -e "${CLR_INFO}4) 🗑️  Удалить ноду${CLR_RESET}"
    echo -e "${CLR_INFO}5) ❌ Выйти${CLR_RESET}"
    echo -e "${CLR_WARNING}Введите номер действия:${CLR_RESET}"
    read -r choice

    case $choice in
        1) install_node ;;
        2) restart_node ;;
        3) view_logs ;;
        4) remove_node ;;
        5) echo -e "${CLR_SUCCESS}Выход...${CLR_RESET}"
            exit 0
            ;;
        *)
            echo -e "${CLR_ERROR}Неверный выбор! Пожалуйста, выберите пункт из меню.${CLR_RESET}"
            show_menu
            ;;
    esac
}

# Запуск меню
show_menu
