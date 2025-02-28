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
    echo -e "${CLR_INFO}          Установочный скрипт для Titan Node              ${CLR_RESET}"
}

# Функция установки зависимостей
function install_dependencies() {
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y wget tar curl
}

# Функция установки ноды Titan
function install_node() {
    echo -e "${CLR_INFO}🚀 Начинаем установку ноды Titan...${CLR_RESET}"
    install_dependencies

    # Указываем директорию установки
    INSTALL_DIR="/root/titan-edge"

    # Скачиваем архив с нодой
    echo -e "${CLR_INFO}🌍 Скачиваем клиент Titan...${CLR_RESET}"
    wget -O /root/titan-edge.tar.gz "https://github.com/Titannet-dao/titan-node/releases/download/v0.1.20/titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz"

    # Удаляем предыдущую папку, если была
    rm -rf "$INSTALL_DIR"

    # Распаковываем архив
    echo -e "${CLR_INFO}📦 Распаковываем файлы...${CLR_RESET}"
    mkdir -p "$INSTALL_DIR"
    tar -xvf /root/titan-edge.tar.gz -C "$INSTALL_DIR" --strip-components=1

    # Проверяем, создалась ли папка
    if [[ ! -d "$INSTALL_DIR" ]]; then
        echo -e "${CLR_ERROR}❌ Ошибка: Папка Titan не была создана!${CLR_RESET}"
        exit 1
    fi

    cd "$INSTALL_DIR" || exit

    # Копируем исполняемые файлы в системные директории
    echo -e "${CLR_INFO}🔑 Устанавливаем Titan Edge...${CLR_RESET}"
    sudo cp titan-edge /usr/local/bin
    sudo cp libgoworkerd.so /usr/local/lib

    # Настройка окружения
    echo -e "${CLR_INFO}🔧 Настраиваем окружение...${CLR_RESET}"
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

    # Запуск ноды
    echo -e "${CLR_INFO}🚀 Запускаем Titan Node...${CLR_RESET}"
    titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0 &

    echo -e "${CLR_SUCCESS}✅ Нода Titan успешно установлена и запущена!${CLR_RESET}"
}

# Функция проверки статуса ноды
function check_status() {
    echo -e "${CLR_INFO}📌 Проверяем статус ноды...${CLR_RESET}"
    titan-edge status
}

# Функция удаления ноды
function remove_node() {
    echo -e "${CLR_ERROR}⚠️ ВНИМАНИЕ: Удаление ноды Titan!${CLR_RESET}"
    sudo systemctl stop titan-edge
    sudo rm -rf /usr/local/bin/titan-edge
    sudo rm -rf /usr/local/lib/libgoworkerd.so
    rm -rf /root/titan-edge
    rm -rf /root/titan-edge.tar.gz
    echo -e "${CLR_SUCCESS}✅ Нода успешно удалена!${CLR_RESET}"
}

# Функция привязки аккаунта
function bind_node() {
    echo -e "${CLR_INFO}🔗 Вставьте ваш идентификационный код:${CLR_RESET}"
    read -r IDENTIFIER

    titan-edge bind --hash="$IDENTIFIER" https://api-test1.container1.titannet.io/api/v2/device/b

    echo -e "${CLR_SUCCESS}✅ Аккаунт успешно привязан!${CLR_RESET}"
}

# Функция отображения меню
function show_menu() {
    show_logo
    echo -e "${CLR_WARNING}📌 Выберите нужное действие:${CLR_RESET}"
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 🔄 Привязать аккаунт${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 📜 Проверить статус ноды${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 🗑️  Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}5) ❌ Выйти${CLR_RESET}"
    read -p "Введите номер действия: " choice

    case $choice in
        1) install_node ;;
        2) bind_node ;;
        3) check_status ;;
        4) remove_node ;;
        5) exit 0 ;;
        *) echo -e "${CLR_ERROR}❌ Ошибка: Некорректный выбор! Попробуйте снова.${CLR_RESET}" ;;
    esac
}

# Запуск меню
show_menu
