#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

function show_logo() {
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${CYAN}     Добро пожаловать в скрипт установки ноды Cysic     ${NC}"
    echo -e "${GREEN}==========================================================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
    }

function install_node() {
    echo -e "${YELLOW}Введите адрес вашего EVM-кошелька:${NC}"
    read -r EVM_ADDRESS

    if [[ -z "$EVM_ADDRESS" ]]; then
        echo -e "${RED}Ошибка: адрес EVM-кошелька не может быть пустым.${NC}"
        exit 1
    fi

    echo -e "${BLUE}Начинается установка ноды Cysic с адресом: ${EVM_ADDRESS}${NC}"
    curl -L https://github.com/cysic-labs/phase2_libs/releases/download/v1.0.0/setup_linux.sh > ~/setup_linux.sh && bash ~/setup_linux.sh "$EVM_ADDRESS"

    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Установка завершена успешно!${NC}"
    else
        echo -e "${RED}Установка завершилась с ошибкой.${NC}"
        exit 1
    fi
}

function remove_node() {
    echo -e "${BLUE}Удаление ноды Cysic...${NC}"

    # Удаляем директорию, если она существует
    if [ -d "$HOME/cysic" ]; then
        rm -rf "$HOME/cysic"
        echo -e "${GREEN}Директория ноды Cysic успешно удалена.${NC}"
    else
        echo -e "${RED}Директория ноды Cysic не найдена.${NC}"
    fi

    # Остановка и удаление службы
    if sudo systemctl is-active --quiet cysic; then
        sudo systemctl stop cysic
        sudo systemctl disable cysic
        sudo rm /etc/systemd/system/cysic.service
        sudo systemctl daemon-reload
        echo -e "${GREEN}Служба Cysic успешно удалена.${NC}"
    else
        echo -e "${RED}Служба Cysic не найдена.${NC}"
    fi

    echo -e "${GREEN}Нода Cysic успешно удалена!${NC}"
}

function show_menu() {
    show_logo
    echo -e "${CYAN}1) 🚀 Установить ноду${NC}"
    echo -e "${CYAN}2) 🗑️  Удалить ноду${NC}"
    echo -e "${CYAN}3) ❌ Выйти${NC}"

    echo -e "${YELLOW}Введите номер действия:${NC}"
    read -r choice

    case $choice in
        1)
            install_node
            ;;
        2)
            remove_node
            ;;
        3)
            echo -e "${GREEN}Выход...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Неверный выбор! Пожалуйста, выберите пункт из меню.${NC}"
            show_menu
            ;;
    esac
}

# Запуск меню
show_menu
