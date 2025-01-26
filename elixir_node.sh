#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Сброс цвета

# Функция отображения логотипа
function show_logo() {
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${CYAN}     Добро пожаловать в скрипт управления нодой Elixir     ${NC}"
    echo -e "${GREEN}==========================================================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция установки ноды
function install_node() {
    local network=$1
    local image=$2
    local container_name=$3
    local port=$4

    echo -e "${BLUE}Установка ноды Elixir в $network...${NC}"

    # Обновление системы и установка зависимостей
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y curl git jq lz4 build-essential unzip docker.io

    sudo systemctl enable docker
    sudo systemctl start docker

    # Установка Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Устанавливаем Docker Compose...${NC}"
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    # Создаем директорию для ноды
    mkdir -p "$HOME/elixir-$network"
    cd "$HOME/elixir-$network" || exit
    wget https://files.elixir.finance/validator.env -O validator.env

    # Ввод данных от пользователя
    echo -e "${YELLOW}Введите IP-адрес сервера:${NC}"
    read -r STRATEGY_EXECUTOR_IP_ADDRESS
    echo -e "${YELLOW}Введите имя валидатора:${NC}"
    read -r STRATEGY_EXECUTOR_DISPLAY_NAME
    echo -e "${YELLOW}Введите адрес EVM:${NC}"
    read -r STRATEGY_EXECUTOR_BENEFICIARY
    echo -e "${YELLOW}Введите приватный ключ EVM:${NC}"
    read -r SIGNER_PRIVATE_KEY

    # Заполняем файл конфигурации
    sed -i "s|ENV=.*|ENV=$network|" validator.env
    echo "STRATEGY_EXECUTOR_IP_ADDRESS=$STRATEGY_EXECUTOR_IP_ADDRESS" >> validator.env
    echo "STRATEGY_EXECUTOR_DISPLAY_NAME=$STRATEGY_EXECUTOR_DISPLAY_NAME" >> validator.env
    echo "STRATEGY_EXECUTOR_BENEFICIARY=$STRATEGY_EXECUTOR_BENEFICIARY" >> validator.env
    echo "SIGNER_PRIVATE_KEY=$SIGNER_PRIVATE_KEY" >> validator.env

    # Запускаем контейнер
    docker pull "$image"
    docker run --name "$container_name" --env-file validator.env --platform linux/amd64 -p "$port:17690" --restart unless-stopped "$image"

    echo -e "${GREEN}Установка завершена!${NC}"
    echo -e "${YELLOW}Для проверки логов используйте:${NC} docker logs -f $container_name"
}

# Функция обновления ноды
function update_node() {
    local network=$1
    local image=$2
    local container_name=$3

    echo -e "${BLUE}Обновляем ноду Elixir в $network...${NC}"
    docker stop "$container_name"
    docker rm "$container_name"

    docker pull "$image"
    docker run --name "$container_name" --env-file "$HOME/elixir-$network/validator.env" --platform linux/amd64 -p 17690:17690 --restart unless-stopped "$image"

    echo -e "${GREEN}Обновление завершено!${NC}"
}

# Функция удаления ноды
function remove_node() {
    local network=$1
    local container_name=$2

    echo -e "${BLUE}Удаляем ноду Elixir в $network...${NC}"
    docker stop "$container_name"
    docker rm "$container_name"
    rm -rf "$HOME/elixir-$network"

    echo -e "${GREEN}Нода успешно удалена!${NC}"
}

# Функция проверки логов
function view_logs() {
    local container_name=$1
    echo -e "${BLUE}Просмотр логов для контейнера $container_name...${NC}"
    docker logs -f "$container_name"
}

# Главное меню
function show_menu() {
    show_logo
    echo -e "${CYAN}1) 🚀 Установить ноду в тестнете${NC}"
    echo -e "${CYAN}2) 🔄 Обновить ноду в тестнете${NC}"
    echo -e "${CYAN}3) 📜 Проверить логи ноды в тестнете${NC}"
    echo -e "${CYAN}4) 🗑️ Удалить ноду в тестнете${NC}"
    echo -e "${CYAN}5) 🚀 Установить ноду в мейннете${NC}"
    echo -e "${CYAN}6) 🔄 Обновить ноду в мейннете${NC}"
    echo -e "${CYAN}7) 📜 Проверить логи ноды в мейннете${NC}"
    echo -e "${CYAN}8) 🗑️ Удалить ноду в мейннете${NC}"
    echo -e "${CYAN}9) ❌ Выйти${NC}"

    echo -e "${YELLOW}Выберите действие:${NC}"
    read -r choice

    case $choice in
        1) install_node "testnet-3" "elixirprotocol/validator:testnet" "elixir" 17690 ;;
        2) update_node "testnet" "elixirprotocol/validator:testnet" "elixir" ;;
        3) view_logs "elixir" ;;
        4) remove_node "testnet" "elixir" ;;
        5) install_node "prod" "elixirprotocol/validator" "elixir-main" 17691 ;;
        6) update_node "prod" "elixirprotocol/validator" "elixir-main" ;;
        7) view_logs "elixir-main" ;;
        8) remove_node "prod" "elixir-main" ;;
        9) echo -e "${GREEN}Выход...${NC}" && exit 0 ;;
        *) echo -e "${RED}Неверный выбор! Попробуйте снова.${NC}" && show_menu ;;
    esac
}

# Запуск скрипта
show_menu
