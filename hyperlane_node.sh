#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Сброс цвета

# Функция для отображения логотипа
function show_logo() {
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${CYAN}      Добро пожаловать в скрипт управления нодой Hyperlane      ${NC}"
    echo -e "${GREEN}==========================================================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Проверка и установка необходимых пакетов
function install_dependencies() {
    echo -e "${YELLOW}Обновляем систему и устанавливаем необходимые зависимости...${NC}"
    sudo apt update && sudo apt upgrade -y
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Установка Docker...${NC}"
        sudo apt install docker.io -y
    else
        echo -e "${GREEN}Docker уже был установлен.${NC}"
    fi
}

# Установка ноды
function install_node() {
    echo -e "${GREEN}Начинаем установку ноды Hyperlane...${NC}"
    install_dependencies

    # Загрузка Docker-образа
    echo -e "${YELLOW}Загружаем Docker-образ ноды...${NC}"
    docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0

    # Запрос данных у пользователя
    echo -e "${YELLOW}Введите имя валидатора:${NC}"
    read -r VALIDATOR_NAME
    echo -e "${YELLOW}Введите приватный ключ вашего EVM кошелька (начиная с 0x):${NC}"
    read -r PRIVATE_KEY
    echo -e "${YELLOW}Введите вашу RPC для сети Base Sepolia:${NC}"
    read -r SEPOLIA_RPC

    # Создание рабочей директории
    mkdir -p $HOME/hyperlane_db_base && chmod -R 777 $HOME/hyperlane_db_base

    # Запуск Docker-контейнера
    docker run -d -it \
        --name hyperlane \
        --mount type=bind,source=$HOME/hyperlane_db_base,target=/hyperlane_db_base \
        gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
        ./validator \
        --db /hyperlane_db_base \
        --originChainName base \
        --reorgPeriod 1 \
        --validator.id "$VALIDATOR_NAME" \
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.folder base \
        --checkpointSyncer.path /hyperlane_db_base/base_checkpoints \
        --validator.key "$PRIVATE_KEY" \
        --chains.base.signer.key "$PRIVATE_KEY" \
        --chains.base.customRpcUrls "$SEPOLIA_RPC,https://base-sepolia-rpc.publicnode.com,http://rpc-base-node-url.com"

    echo -e "${GREEN}Нода Hyperlane успешно установлена и запущена!${NC}"
}

# Обновление ноды
function update_node() {
    echo -e "${BLUE}Обновляем ноду Hyperlane...${NC}"
    docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0
    echo -e "${GREEN}Нода успешно обновлена до последней версии!${NC}"
}

# Просмотр логов
function view_logs() {
    echo -e "${BLUE}Открываем логи ноды Hyperlane...${NC}"
    docker logs --tail 100 -f hyperlane
}

# Удаление ноды
function remove_node() {
    echo -e "${RED}Удаление ноды Hyperlane...${NC}"

    # Остановка и удаление Docker-контейнера
    docker stop hyperlane
    docker rm hyperlane

    # Удаление данных ноды
    if [ -d "$HOME/hyperlane_db_base" ]; then
        rm -rf $HOME/hyperlane_db_base
        echo -e "${GREEN}Директория ноды удалена.${NC}"
    else
        echo -e "${RED}Директория ноды не найдена.${NC}"
    fi

    echo -e "${GREEN}Нода Hyperlane успешно удалена!${NC}"
}

# Меню управления
function show_menu() {
    show_logo
    echo -e "${CYAN}1) 🚀 Установить ноду${NC}"
    echo -e "${CYAN}2) 🔄 Обновить ноду${NC}"
    echo -e "${CYAN}3) 📜 Просмотр логов${NC}"
    echo -e "${CYAN}4) 🗑️ Удалить ноду${NC}"
    echo -e "${CYAN}5) ❌ Выйти${NC}"

    echo -e "${YELLOW}Введите номер действия:${NC}"
    read -r choice

    case $choice in
        1) install_node ;;
        2) update_node ;;
        3) view_logs ;;
        4) remove_node ;;
        5) echo -e "${GREEN}Выход...${NC}" ;;
        *) echo -e "${RED}Неверный выбор! Попробуйте снова.${NC}" ;;
    esac
}

# Запуск меню
show_menu
