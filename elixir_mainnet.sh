#!/bin/bash

# Определяем цветовую схему для вывода текста
CLR_RST="\e[0m"
CLR_RED="\e[31m"
CLR_GRN="\e[32m"
CLR_YLW="\e[33m"
CLR_BLU="\e[34m"
CLR_PRP="\e[35m"
CLR_CYN="\e[36m"

# Функция отображения логотипа
function show_logo() {
    echo -e "${CLR_GRN}==========================================================${CLR_RST}"
    echo -e "${CLR_CYN}       Добро пожаловать в установщик ноды Elixir Mainnet    ${CLR_RST}"
    echo -e "${CLR_GRN}==========================================================${CLR_RST}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Установка зависимостей
function install_dependencies() {
    echo -e "${CLR_YLW}▶ Проверка и установка зависимостей...${CLR_RST}"
    sudo apt update -y
    sudo apt install -y curl git jq lz4 build-essential unzip docker.io

    sudo systemctl enable docker
    sudo systemctl start docker
}

# Установка ноды
function install_node() {
    echo -e "${CLR_BLU}▶ Устанавливаем ноду Elixir в мейннете...${CLR_RST}"

    INSTALL_DIR="$HOME/elixir-mainnet"
    CONFIG_FILE="$INSTALL_DIR/validator.env"

    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR" || exit
    wget https://files.elixir.finance/validator.env -O "$CONFIG_FILE"

    echo -e "${CLR_YLW}Введите IP-адрес сервера:${CLR_RST}"
    read -r IP_ADDR
    echo -e "${CLR_YLW}Введите имя валидатора:${CLR_RST}"
    read -r NODE_NAME
    echo -e "${CLR_YLW}Введите адрес EVM:${CLR_RST}"
    read -r WALLET
    echo -e "${CLR_YLW}Введите приватный ключ EVM:${CLR_RST}"
    read -r PRIV_KEY

    sed -i "s|ENV=.*|ENV=prod|" "$CONFIG_FILE"
    echo "STRATEGY_EXECUTOR_IP_ADDRESS=$IP_ADDR" >> "$CONFIG_FILE"
    echo "STRATEGY_EXECUTOR_DISPLAY_NAME=$NODE_NAME" >> "$CONFIG_FILE"
    echo "STRATEGY_EXECUTOR_BENEFICIARY=$WALLET" >> "$CONFIG_FILE"
    echo "SIGNER_PRIVATE_KEY=$PRIV_KEY" >> "$CONFIG_FILE"

    docker pull elixirprotocol/validator
    docker run --name elixir_mainnet_node --env-file "$CONFIG_FILE" --platform linux/amd64 -p 17691:17690 --restart unless-stopped elixirprotocol/validator

    echo -e "${CLR_GRN}✅ Установка завершена!${CLR_RST}"
}

# Обновление ноды
function update_node() {
    echo -e "${CLR_BLU}▶ Обновляем ноду Elixir Mainnet...${CLR_RST}"

    docker stop elixir_mainnet_node
    docker rm elixir_mainnet_node
    docker pull elixirprotocol/validator
    docker run --name elixir_mainnet_node --env-file "$HOME/elixir-mainnet/validator.env" --platform linux/amd64 -p 17691:17690 --restart unless-stopped elixirprotocol/validator

    echo -e "${CLR_GRN}✅ Обновление завершено!${CLR_RST}"
}

# Просмотр логов
function view_logs() {
    echo -e "${CLR_BLU}▶ Просмотр логов ноды...${CLR_RST}"
    docker logs -f elixir_mainnet_node
}

# Удаление ноды
function remove_node() {
    echo -e "${CLR_BLU}▶ Удаляем ноду Elixir Mainnet...${CLR_RST}"
    docker stop elixir_mainnet_node
    docker rm elixir_mainnet_node
    rm -rf "$HOME/elixir-mainnet"
    echo -e "${CLR_GRN}✅ Нода успешно удалена!${CLR_RST}"
}

# Меню выбора
function show_menu() {
    show_logo
    echo -e "${CLR_CYN}1) 🚀 Установить ноду${CLR_RST}"
    echo -e "${CLR_CYN}2) 🔄 Обновить ноду${CLR_RST}"
    echo -e "${CLR_CYN}3) 📜 Просмотреть логи${CLR_RST}"
    echo -e "${CLR_CYN}4) 🗑️ Удалить ноду${CLR_RST}"
    echo -e "${CLR_CYN}5) ❌ Выйти${CLR_RST}"
    
    read -r choice

    case $choice in
        1) install_dependencies; install_node ;;
        2) update_node ;;
        3) view_logs ;;
        4) remove_node ;;
        5) exit 0 ;;
        *) echo -e "${CLR_RED}Ошибка: Неверный ввод!${CLR_RST}" && show_menu ;;
    esac
}

show_menu
