#!/bin/bash

# Оформление текста: цвета и фоны
CLR_INFO='\033[1;97;44m'  # Белый текст на синем фоне
CLR_SUCCESS='\033[1;30;42m'  # Зеленый текст на черном фоне
CLR_WARNING='\033[1;37;41m'  # Белый текст на красном фоне
CLR_ERROR='\033[1;31;40m'  # Красный текст на черном фоне
CLR_GREEN='\033[0;32m' #Зеленый текст
CLR_RESET='\033[0m'  # Сброс форматирования

function show_logo() {
    echo -e "${CLR_GREEN}==========================================================${CLR_RESET}"
    echo -e "${CLR_GREEN}     Добро пожаловать в скрипт управления нодой Cysic     ${CLR_RESET}"
    echo -e "${CLR_GREEN}==========================================================${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

function install_node() {
    echo -e "${CLR_INFO}Введите адрес вашего EVM-кошелька:${CLR_RESET}"
    read -r EVM_ADDRESS

    if [[ -z "$EVM_ADDRESS" ]]; then
        echo -e "${CLR_ERROR}Ошибка: адрес EVM-кошелька не может быть пустым.${CLR_RESET}"
        exit 1
    fi

    echo -e "${CLR_INFO}Начинается установка ноды Cysic с адресом: ${EVM_ADDRESS}${CLR_RESET}"
    curl -L https://github.com/cysic-labs/phase2_libs/releases/download/v1.0.0/setup_linux.sh > ~/setup_linux.sh && bash ~/setup_linux.sh "$EVM_ADDRESS"

    if [[ $? -eq 0 ]]; then
        echo -e "${CLR_SUCCESS}Установка завершена успешно!${CLR_RESET}"

        # Создание сервиса
        echo -e "${CLR_INFO}Создаем системный сервис для ноды Cysic...${CLR_RESET}"
        sudo bash -c 'cat > /etc/systemd/system/cysic.service <<EOF
[Unit]
Description=Cysic Verifier Node
After=network.target

[Service]
User=root
Group=root
WorkingDirectory=/root/cysic-verifier
Environment="LD_LIBRARY_PATH=/root/cysic-verifier"
Environment="CHAIN_ID=534352"
ExecStart=/root/cysic-verifier/verifier
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF'

        # Запуск ноды
        sudo systemctl daemon-reload
        sudo systemctl enable cysic.service
        sudo systemctl start cysic.service

        echo -e "${CLR_SUCCESS}Сервис Cysic успешно создан и запущен!${CLR_RESET}"
    else
        echo -e "${CLR_WARNING}Установка завершилась с ошибкой.${CLR_RESET}"
        exit 1
    fi
}

function remove_node() {
    echo -e "${CLR_INFO}Удаление ноды Cysic...${CLR_RESET}"

    # Остановка и удаление службы
    if sudo systemctl is-active --quiet cysic; then
        sudo systemctl stop cysic
        sudo systemctl disable cysic
        sudo rm /etc/systemd/system/cysic.service
        sudo systemctl daemon-reload
        echo -e "${CLR_SUCCESS}Служба Cysic успешно удалена.${CLR_RESET}"
    else
        echo -e "${CLR_WARNING}Служба Cysic не найдена.${CLR_RESET}"
    fi

    # Удаление файлов
    if [ -d "$HOME/cysic-verifier" ]; then
        rm -rf "$HOME/cysic-verifier"
        echo -e "${CLR_SUCCESS}Файлы ноды Cysic успешно удалены.${CLR_RESET}"
    else
        echo -e "${CLR_WARNING}Директория ноды Cysic не найдена.${CLR_RESET}"
    fi

    echo -e "${CLR_SUCCESS}Нода Cysic успешно удалена!${CLR_RESET}"
}

function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 🗑️  Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}3) ❌ Выйти${CLR_RESET}"

    echo -e "${CLR_INFO}Введите номер действия:${CLR_RESET}"
    read -r choice

    case $choice in
        1)
            install_node
            ;;
        2)
            remove_node
            ;;
        3)
            echo -e "${CLR_WARNING}Выход...${CLR_RESET}"
            exit 0
            ;;
        *)
            echo -e "${CLR_WARNING}Неверный выбор! Пожалуйста, выберите пункт из меню.${CLR_RESET}"
            show_menu
            ;;
    esac
}

# Запуск меню
show_menu
