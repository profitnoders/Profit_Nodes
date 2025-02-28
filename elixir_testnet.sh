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
    echo -e "${CLR_INFO}      Добро пожаловать в установщик ноды Elixir Testnet    ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Проверка и установка зависимостей
function install_dependencies() {
    sudo apt update -y
    sudo apt install -y curl git jq lz4 build-essential unzip docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
}

# Установка ноды
function install_node() {
    echo -e "${CLR_INFO}▶ Устанавливаем ноду Elixir в тестнете...${CLR_RESET}"

    INSTALL_DIR="$HOME/elixir-testnet"
    CONFIG_FILE="$INSTALL_DIR/validator.env"

    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR" || exit
    wget https://files.elixir.finance/validator.env -O "$CONFIG_FILE"

    echo -e "${CLR_ERROR}Введите имя для ноды валидатора:${CLR_RESET}"
    read -r NODE_NAME
    echo -e "${CLR_ERROR}Введите адрес кошелька EVM:${CLR_RESET}"
    read -r WALLET
    echo -e "${CLR_ERROR}Введите private key от EVM кошелька:${CLR_RESET}"
    read -r PRIV_KEY
    echo -e "${CLR_ERROR}Введите IP-адрес вашего сервера:${CLR_RESET}"
    read -r IP_ADDR

    # Заполняем файл конфигурации
    sed -i "s|ENV=.*|ENV=testnet-3|" "$CONFIG_FILE"
    echo "STRATEGY_EXECUTOR_IP_ADDRESS=$IP_ADDR" >> "$CONFIG_FILE"
    echo "STRATEGY_EXECUTOR_DISPLAY_NAME=$NODE_NAME" >> "$CONFIG_FILE"
    echo "STRATEGY_EXECUTOR_BENEFICIARY=$WALLET" >> "$CONFIG_FILE"
    echo "SIGNER_PRIVATE_KEY=$PRIV_KEY" >> "$CONFIG_FILE"

    docker pull elixirprotocol/validator:testnet
    docker run --name elixir_testnet_node --env-file "$CONFIG_FILE" --platform linux/amd64 -p 17690:17690 --restart unless-stopped elixirprotocol/validator:testnet

    echo -e "${CLR_SUCCESS}✅ Установка завершена!${CLR_RESET}"
}

# Обновление ноды
function update_node() {
    echo -e "${CLR_INFO}▶ Обновляем ноду Elixir Testnet...${CLR_RESET}"

    docker stop elixir_testnet_node
    docker rm elixir_testnet_node
    docker pull elixirprotocol/validator:testnet
    docker run --name elixir_testnet_node --env-file "$HOME/elixir-testnet/validator.env" --platform linux/amd64 -p 17690:17690 --restart unless-stopped elixirprotocol/validator:testnet

    echo -e "${CLR_SUCCESS}✅ Обновление завершено!${CLR_RESET}"
}

# Просмотр логов
function view_logs() {
    echo -e "${CLR_INFO}▶ Просмотр логов...${CLR_RESET}"
    docker logs -f elixir_testnet_node
}

# Удаление ноды
function remove_node() {
    docker stop elixir_testnet_node
    docker rm elixir_testnet_node
    rm -rf "$HOME/elixir-testnet"
    echo -e "${CLR_SUCCESS}✅ Нода успешно удалена!${CLR_RESET}"
}

# Меню
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 🔄 Обновить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 📜 Просмотреть логи${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 🗑️ Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}5) ❌ Выйти${CLR_RESET}"

    echo -e "${CLR_WARNING}Введите номер действия:${CLR_RESET}"
    read -r choice
    case $choice in
        1) install_dependencies; install_node ;;
        2) update_node ;;
        3) view_logs ;;
        4) remove_node ;;
        5) exit 0 ;;
        *) echo -e "${CLR_RED}Ошибка: Неверный ввод!${CLR_RESET}" && show_menu ;;
    esac
}

show_menu
