#!/bin/bash

# Цветовая схема
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
    echo -e "${CLR_CYN}       Добро пожаловать в установщик ноды Privasea        ${CLR_RST}"
    echo -e "${CLR_GRN}==========================================================${CLR_RST}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция установки зависимостей
function install_dependencies() {
    echo -e "${CLR_YLW}▶ Обновление системы и установка зависимостей...${CLR_RST}"
    sudo apt update -y && sudo apt upgrade -y
    sudo apt-get install -y ca-certificates curl gnupg

    echo -e "${CLR_YLW}▶ Установка Docker...${CLR_RST}"
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update -y && sudo apt upgrade -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo -e "${CLR_GRN}✅ Установка зависимостей завершена.${CLR_RST}"
}

# Функция установки ноды
function install_node() {
    echo -e "${CLR_BLU}▶ Скачиваем Docker-образ Privasea...${CLR_RST}"
    docker pull privasea/acceleration-node-beta:latest

    echo -e "${CLR_YLW}▶ Создание каталога и генерация ключа...${CLR_RST}"
    mkdir -p ~/privasea/config && cd ~/privasea

    echo -e "${CLR_CYN}▶ Введите пароль для хранилища ключей:${CLR_RST}"
    read -s NODE_PASSWORD

    docker run --rm -it -v "$HOME/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore

    echo -e "${CLR_YLW}▶ Скопируйте и сохраните ваш Node Address и Node Filename!${CLR_RST}"
    cd config/
    ls

    echo -e "${CLR_CYN}▶ Введите UTC_СТРОКА (Node Filename), которую вы скопировали:${CLR_RST}"
    read NODE_FILENAME
    mv "$HOME/privasea/config/$NODE_FILENAME" "$HOME/privasea/config/wallet_keystore"

    echo -e "${CLR_BLU}▶ Запускаем ноду Privasea...${CLR_RST}"
    KEYSTORE_PASSWORD="$NODE_PASSWORD" && docker run -d --name privanetix-node -v "$HOME/privasea/config:/app/config" -e KEYSTORE_PASSWORD="$NODE_PASSWORD" privasea/acceleration-node-beta:latest

    echo -e "${CLR_GRN}✅ Установка завершена!${CLR_RST}"
    echo -e "${CLR_YLW}Для просмотра логов используйте:${CLR_RST} docker logs -f privanetix-node"
}

#Функция перезапуска ноды и контейнера
function restart_node() {
    echo -e "${CLR_BLU} Перезапуск контейнера ноды ${CLR_BLUE}"
    docker restart /privanetix-node
}

# Функция просмотра логов
function view_logs() {
    echo -e "${CLR_BLU}▶ Просмотр логов ноды Privasea...${CLR_RST}"
    docker logs -f privanetix-node
}

# Функция удаления ноды
function remove_node() {
    echo -e "${CLR_BLU}▶ Удаление ноды Privasea...${CLR_RST}"
    docker stop privanetix-node
    docker rm privanetix-node
    rm -rf ~/privasea
    echo -e "${CLR_GRN}✅ Нода успешно удалена!${CLR_RST}"
}

# Меню выбора
function show_menu() {
    show_logo
    echo -e "${CLR_CYN}1) 🚀 Установить ноду${CLR_RST}"
    echo -e "${CLR_CYN}2) 🔄 Перезапустить ноду${CLR_RST}"
    echo -e "${CLR_CYN}3) 📜 Просмотреть логи${CLR_RST}"
    echo -e "${CLR_CYN}4) 🗑️ Удалить ноду${CLR_RST}"
    echo -e "${CLR_CYN}5) ❌ Выйти${CLR_RST}"
    
    read -r choice

    case $choice in
        1) install_dependencies; install_node ;;
        2) restart_node ;;
        3) view_logs ;;
        4) remove_node ;;
        5) exit 0 ;;
        *) echo -e "${CLR_RED}Ошибка: Неверный ввод!${CLR_RST}" && show_menu ;;
    esac
}

show_menu
