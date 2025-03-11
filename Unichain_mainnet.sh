#!/bin/bash

# Оформление текста: цвета и фоны
CLR_INFO='\033[1;97;44m'  # Белый текст на синем фоне
CLR_SUCCESS='\033[1;30;42m'  # Зеленый текст на черном фоне
CLR_WARNING='\033[1;37;41m'  # Белый текст на красном фоне
CLR_ERROR='\033[1;31;40m'  # Красный текст на черном фоне
CLR_RESET='\033[0m'  # Сброс форматирования


function show_logo() {
    echo -e "${CLR_INFO}     Добро пожаловать в скрипт управления нодой Unichain mainnet     ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция установки необходимых пакетов
function install_dependencies() {
    echo -e "${CLR_INFO}Обновляем систему...${CLR_RESET}"
    sudo apt update && sudo apt upgrade -y
    
    echo -e "${CLR_INFO}Устанавливаем Docker...${CLR_RESET}"
    sudo apt install docker.io -y
    
    echo -e "${CLR_INFO}Устанавливаем Docker Compose...${CLR_RESET}"
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
}

# Функция установки ноды
function install_node() {
    install_dependencies
    echo -e "${CLR_INFO}Скачиваем Unichain ноду...${CLR_RESET}"
    git clone https://github.com/Uniswap/unichain-node $HOME/unichain-node
    
    echo -e "${CLR_SUCCESS}Нода успешно скачана! Теперь настройте файл конфигурации вручную.${CLR_RESET}"
    echo -e "${CLR_WARNING}Редактируйте файл .env.mainnet и docker-compose.yml перед запуском!${CLR_RESET}"
    echo -e "${CLR_INFO}Используйте команды:${CLR_RESET}"
    echo -e "nano $HOME/unichain-node/.env.mainnet"
    echo -e "nano $HOME/unichain-node/docker-compose.yml"
}

# Функция запуска ноды
function start_node() {
    echo -e "${CLR_INFO}Запускаем ноду...${CLR_RESET}"
    docker-compose -f $HOME/unichain-node/docker-compose.yml up -d
    echo -e "${CLR_SUCCESS}Нода запущена!${CLR_RESET}"
}

# Функция остановки ноды
function stop_node() {
    echo -e "${CLR_INFO}Останавливаем ноду...${CLR_RESET}"
    docker-compose -f $HOME/unichain-node/docker-compose.yml down
    echo -e "${CLR_SUCCESS}Нода остановлена!${CLR_RESET}"
}

# Функция просмотра логов
function check_logs() {
    echo -e "${CLR_INFO}Просмотр логов ноды...${CLR_RESET}"
    docker-compose -f $HOME/unichain-node/docker-compose.yml logs -f
}

# Функция удаления ноды с подтверждением
function remove_node() {
    echo -e "${CLR_WARNING}Вы уверены, что хотите удалить ноду? (y/n)${CLR_RESET}"
    read -r confirm
    if [[ "$confirm" == "y" ]]; then
        echo -e "${CLR_INFO}Удаляем ноду Unichain...${CLR_RESET}"
        docker-compose -f $HOME/unichain-node/docker-compose.yml down -v
        rm -rf $HOME/unichain-node
        echo -e "${CLR_SUCCESS}Нода успешно удалена!${CLR_RESET}"
    else
        echo -e "${CLR_SUCCESS}Удаление отменено.${CLR_RESET}"
    fi
}

# Функция проверки работы ноды
function check_status() {
    echo -e "${CLR_INFO}Проверяем работу ноды...${CLR_RESET}"
    curl -d '{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
    -H "Content-Type: application/json" http://localhost:8545
}

# Меню выбора действий
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) ✅ Запустить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}3) ⏹ Остановить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 📜 Просмотр логов${CLR_RESET}"
    echo -e "${CLR_GREEN}5) 🔍 Проверить статус ноды${CLR_RESET}"
    echo -e "${CLR_GREEN}6) 🗑 Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}7) ❌ Выйти${CLR_RESET}"
    echo -e "${CLR_INFO}Введите номер:${CLR_RESET}"
    read -r choice

    case $choice in
        1) install_node ;;
        2) start_node ;;
        3) stop_node ;;
        4) check_logs ;;
        5) check_status ;;
        6) remove_node ;;
        7) echo -e "${CLR_ERROR}Выход...${CLR_RESET}" ;;
        *) echo -e "${CLR_WARNING}Неверный выбор. Попробуйте снова.${CLR_RESET}" ;;
    esac
}

# Запуск меню
show_menu
