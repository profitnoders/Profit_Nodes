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
    echo -e "${CLR_INFO}       Добро пожаловать в установщик ноды Privasea        ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция установки зависимостей
function install_dependencies() {
    sudo apt update -y && sudo apt upgrade -y
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update -y && sudo apt upgrade -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo -e "${CLR_SUCCESS}✅ Установка зависимостей завершена.${CLR_RESET}"
}

# Функция установки ноды
function install_node() {
    docker pull privasea/acceleration-node-beta:latest
    mkdir -p ~/privasea/config && cd ~/privasea
    read -s NODE_PASSWORD

    docker run --rm -it -v "$HOME/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore

    echo -e "${CLR_ERROR}▶ Скопируйте и сохраните ваш Node Address и Node Filename!${CLR_RESET}"
    cd config/
    ls

    echo -e "${CLR_ERROR}▶ Введите UTC_СТРОКА (Node Filename), которую вы скопировали:${CLR_RESET}"
    read NODE_FILENAME
    mv "$HOME/privasea/config/$NODE_FILENAME" "$HOME/privasea/config/wallet_keystore"

    echo -e "${CLR_ERROR}▶ Запускаем ноду Privasea...${CLR_RESET}"
    KEYSTORE_PASSWORD="$NODE_PASSWORD" && docker run -d --name privanetix-node -v "$HOME/privasea/config:/app/config" -e KEYSTORE_PASSWORD="$NODE_PASSWORD" privasea/acceleration-node-beta:latest

    echo -e "${CLR_SUCCESS}✅ Установка завершена!${CLR_RESET}"
}

#Функция перезапуска ноды и контейнера
function restart_node() {
    docker restart /privanetix-node
    echo -e "${CLR_SUCCESS} Нода перезапущена ${CLR_RESET}"
}

# Функция просмотра логов
function view_logs() {
    echo -e "${CLR_INFO}▶Логи ноды Privasea...${CLR_RESET}"
    docker logs -f privanetix-node
}

# Функция удаления ноды
function remove_node() {
    docker stop privanetix-node
    docker rm privanetix-node
    rm -rf ~/privasea
    echo -e "${CLR_SUCCESS}✅ Нода успешно удалена!${CLR_RESET}"
}

# Меню выбора
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 🔄 запустить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 📜 Просмотреть логи${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 🗑️ Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}5) ❌ Выйти${CLR_RESET}"

    echo -e "${CLR_INFO}Введите номер действия:${CLR_RESET}"
    read -r choice

    case $choice in
        1) install_dependencies; install_node ;;
        2) restart_node ;;
        3) view_logs ;;
        4) remove_node ;;
        5) exit 0 ;;
        *) echo -e "${CLR_ERROR}Ошибка: Неверный ввод!${CLR_RESET}" && show_menu ;;
    esac
}

show_menu
