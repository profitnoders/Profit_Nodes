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
}

function restart_node() {
    echo -e "${CLR_WARNING}Перезапуск ноды Cysic...${CLR_RESET}"
    if [ -f "$HOME/cysic-verifier/start.sh" ]; then
        cd "$HOME/cysic-verifier" || exit
        bash start.sh
        echo -e "${CLR_SUCCESS}Нода перезапущена.${CLR_RESET}"
    else
        echo -e "${CLR_ERROR}Файл start.sh не найден. Убедитесь, что нода установлена.${CLR_RESET}"
    fi
}

function view_logs() {
    LOGFILE="$HOME/cysic-verifier/logs.txt"
    if [ -f "$LOGFILE" ]; then
        echo -e "${CLR_WARNING}Показ последних 100 строк логов:${CLR_RESET}"
        tail -n 100 "$LOGFILE"
    else
        echo -e "${CLR_ERROR}Файл логов не найден: $LOGFILE${CLR_RESET}"
    fi
}

function remove_node() {
    echo -e "${CLR_WARNING}Удаление ноды Cysic...${CLR_RESET}"

    if [ -d "$HOME/cysic-verifier" ]; then
        rm -rf "$HOME/cysic-verifier"
        echo -e "${CLR_SUCCESS}Директория ноды Cysic успешно удалена.${CLR_RESET}"
    else
        echo -e "${CLR_ERROR}Директория ноды Cysic не найдена.${CLR_RESET}"
    fi

    if sudo systemctl is-active --quiet cysic; then
        sudo systemctl stop cysic
        sudo systemctl disable cysic
        sudo rm /etc/systemd/system/cysic.service
        sudo systemctl daemon-reload
        echo -e "${CLR_SUCCESS}Служба Cysic успешно удалена.${CLR_RESET}"
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
    echo -e "${CLR_INFO}Введите номер действия:${CLR_RESET}"
    read -p "Выбор: " choice

    case $choice in
        1) install_node ;;
        2) restart_node ;;
        3) view_logs ;;
        4) remove_node ;;
        5)
            echo -e "${CLR_SUCCESS}Выход...${CLR_RESET}"
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
