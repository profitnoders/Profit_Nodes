#!/bin/bash

# Оформление текста: цвета и фоны
CLR_INFO='\033[1;97;44m'  # Белый текст на синем фоне
CLR_SUCCESS='\033[1;97;42m'  # Белый текст на зеленом фоне
CLR_WARNING='\033[1;30;103m'  # Черный текст на желтом фоне
CLR_ERROR='\033[1;97;41m'  # Белый текст на красном фоне
CLR_RESET='\033[0m'  # Сброс форматирования

# Функция для отображения приветственного баннера
function show_logo() {
    echo -e "${CLR_SUCCESS}**********************************************************${CLR_RESET}"
    echo -e "${CLR_INFO}          Установочный скрипт для Nexus Node              ${CLR_RESET}"
    echo -e "${CLR_SUCCESS}**********************************************************${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция подготовки окружения: установка пакетов и зависимостей
function install_dependencies() {
    echo -e "${CLR_WARNING}🔄 Проверяем и устанавливаем необходимые зависимости...${CLR_RESET}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y build-essential pkg-config libssl-dev git-all protobuf-compiler cargo screen unzip
    sudo apt install -y curl

    # Установка Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    rustup update

    # Обновление protobuf
    sudo apt remove -y protobuf-compiler
    curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v25.2/protoc-25.2-linux-x86_64.zip
    unzip protoc-25.2-linux-x86_64.zip -d $HOME/.local
    export PATH="$HOME/.local/bin:$PATH"
    protoc --version
}

# Функция установки ноды Nexus
function install_node() {
    echo -e "${CLR_INFO}🚀 Запускаем процесс установки Nexus Node...${CLR_RESET}"
    
    # Создание и запуск screen-сессии с выполнением команды установки
    screen -dmS nexus bash -c 'curl https://cli.nexus.xyz/ | sh'

    echo -e "${CLR_SUCCESS}✅ Установка завершена! Узел запущен в screen-сессии 'nexus'.${CLR_RESET}"
}

# Функция просмотра логов ноды
function view_logs() {
    echo -e "${CLR_INFO}📜 Отображение логов ноды...${CLR_RESET}"
    screen -r nexus
}

# Функция перезапуска ноды
function restart_node() {
    echo -e "${CLR_WARNING}🔄 Перезапускаем ноду Nexus...${CLR_RESET}"
    screen -S nexus -X quit
    screen -dmS nexus
    curl https://cli.nexus.xyz/ | sh
    echo -e "${CLR_SUCCESS}✅ Нода перезапущена!${CLR_RESET}"
}

# Функция удаления ноды
function remove_node() {
    echo -e "${CLR_ERROR}⚠️ ВНИМАНИЕ: Удаление ноды Nexus!${CLR_RESET}"
    screen -S nexus -X quit
    rm -rf $HOME/.nexus
    rm -rf nexus_node.sh
    echo -e "${CLR_SUCCESS}✅ Нода успешно удалена!${CLR_RESET}"
}

# Функция отображения меню
function show_menu() {
    show_logo
    echo -e "${CLR_WARNING}📌 Выберите нужное действие:${CLR_RESET}"
    echo -e "${CLR_INFO}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_INFO}2) 🔄 Перезапустить ноду${CLR_RESET}"
    echo -e "${CLR_INFO}3) 📜 Открыть Screen сессию Nexus${CLR_RESET}"
    echo -e "${CLR_INFO}4) 🗑️ Удалить ноду${CLR_RESET}"
    echo -e "${CLR_INFO}5) ❌ Выйти${CLR_RESET}"
    read -p "Введите номер действия: " choice

    case $choice in
        1) install_dependencies; install_node ;;
        2) restart_node ;;
        3) view_logs ;;
        4) remove_node ;;
        5) exit 0 ;;
        *) echo -e "${CLR_ERROR}❌ Ошибка: Некорректный выбор! Попробуйте снова.${CLR_RESET}" ;;
    esac
}

# Запуск скрипта
show_menu
