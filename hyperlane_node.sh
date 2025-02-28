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
    echo -e "${CLR_INFO}      Добро пожаловать в скрипт управления нодой Hyperlane      ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Проверка и установка необходимых пакетов
function install_dependencies() {
    sudo apt update && sudo apt upgrade -y
    if ! command -v docker &> /dev/null; then
        sudo apt install docker.io -y
    else
        echo -e "${CLR_SUCCESS}Docker уже установлен.${CLR_RESET}"
    fi
}

# Установка ноды
function install_node() {
    install_dependencies

    echo -e "${CLR_INFO}Загружаем Docker-образ ноды...${CLR_RESET}"
    docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0

    # Запрос данных у пользователя
    echo -e ${CLR_INFO}"Введите имя валидатора:${CLR_RESET}"
    read -r VALIDATOR_NAME
    echo -e ${CLR_INFO}"Введите private key EVM кошелька:${CLR_RESET}"
    read -r PRIVATE_KEY
    echo -e ${CLR_INFO}"Введите вашу RPC для сети Base Mainnet:${CLR_RESET}"
    read -r BASE_MAINNET_RPC

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
        --chains.base.customRpcUrls "$BASE_MAINNET_RPC,wss://base-rpc.publicnode.com,http://rpc-base-node-url.com"

    echo -e "${CLR_SUCCESS}Нода Hyperlane успешно установлена и запущена!${CLR_RESET}"
}

# Обновление ноды
function update_node() {
    docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0
    echo -e "${CLR_SUCCESS}Нода успешно обновлена до последней версии!${CLR_RESET}"
}

# Просмотр логов
function view_logs() {
    echo -e "${CLR_INFO}Логи ноды Hyperlane...${CLR_RESET}"
    docker logs --tail 100 -f hyperlane
}

# Удаление ноды
function remove_node() {
    docker stop hyperlane
    docker rm hyperlane
    if [ -d "$HOME/hyperlane_db_base" ]; then
        rm -rf $HOME/hyperlane_db_base
        echo -e "${CLR_SUCCESS}Нода Hyperlane удалена.${CLR_RESET}"
    else
        echo -e "${CLR_ERROR}Директория ноды не найдена.${CLR_RESET}"
    fi

}

# Меню управления
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 🔄 Обновить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 📜 Просмотр логов${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 🗑️ Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}5) ❌ Выйти${CLR_RESET}"

    echo -e "${CLR_INFO}Введите номер действия:${CLR_RESET}"
    read -r choice

    case $choice in
        1) install_node ;;
        2) update_node ;;
        3) view_logs ;;
        4) remove_node ;;
        5) echo -e "${CLR_ERROR}Выход...${CLR_RESET}" ;;
        *) echo -e "${CLR_WARNING}Неверный выбор! Попробуйте снова.${CLR_RESET}" ;;
    esac
}

# Запуск меню
show_menu
