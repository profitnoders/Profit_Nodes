#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Сброс цвета

# Логотип
function show_logo() {
    echo -e "${GREEN}===============================${NC}"
    echo -e "${CYAN}  Добро пожаловать в скрипт установки ноды Multiple  ${NC}"
    echo -e "${GREEN}===============================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Установка необходимых пакетов
function install_dependencies() {
    echo -e "${YELLOW}Обновляем систему и устанавливаем зависимости...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl tar wget
}

# Установка ноды Multiple
function install_node() {
    echo -e "${BLUE}🚀 Начинаем установку ноды Multiple...${NC}"
    install_dependencies

    # Проверяем архитектуру системы
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        CLIENT_URL="https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/MultipleForLinux.tar"
    elif [[ "$ARCH" == "aarch64" ]]; then
        CLIENT_URL="https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/MultipleForLinux.tar"
    else
        echo -e "${RED}❌ Архитектура системы не поддерживается: $ARCH${NC}"
        exit 1
    fi

    # Определяем путь установки
    INSTALL_DIR="$HOME/multipleforlinux"
    
    # Удаляем старую папку, если она есть, чтобы избежать проблем с дубликатами
    if [[ -d "$INSTALL_DIR" ]]; then
        echo -e "${YELLOW}⚠️ Найдена старая установка, удаляем...${NC}"
        rm -rf "$INSTALL_DIR"
    fi

    # Скачиваем клиент в корневую папку пользователя
    echo -e "${BLUE}📥 Скачиваем клиент с $CLIENT_URL...${NC}"
    wget --header="User-Agent: Mozilla/5.0" -O "$HOME/MultipleForLinux.tar" "$CLIENT_URL" || {
        echo -e "${RED}❌ Ошибка: Не удалось скачать файл. Проверьте URL.${NC}"
        exit 1
    }

    # Распаковываем архив прямо в $HOME, чтобы папка multipleforlinux появилась в /root
    echo -e "${BLUE}📦 Распаковываем файлы...${NC}"
    tar -xvf "$HOME/MultipleForLinux.tar" -C "$HOME" || {
        echo -e "${RED}❌ Ошибка: Файл не является архивом или поврежден.${NC}"
        exit 1
    }

    # Проверяем, создалась ли папка multipleforlinux
    if [[ ! -d "$INSTALL_DIR" ]]; then
        echo -e "${RED}❌ Ошибка: Папка multipleforlinux не была создана!${NC}"
        exit 1
    fi

    cd "$INSTALL_DIR" || {
        echo -e "${RED}❌ Ошибка: Не удалось перейти в директорию multipleforlinux!${NC}"
        exit 1
    }

    # Проверяем, существуют ли файлы multiple-cli и multiple-node
    if [[ ! -f "$INSTALL_DIR/multiple-cli" ]] || [[ ! -f "$INSTALL_DIR/multiple-node" ]]; then
        echo -e "${RED}❌ Ошибка: Файлы multiple-cli или multiple-node отсутствуют!${NC}"
        exit 1
    fi

    # Даем файлам права на выполнение
    chmod +x "$INSTALL_DIR/multiple-cli"
    chmod +x "$INSTALL_DIR/multiple-node"

    # Запускаем ноду
    echo -e "${BLUE}🚀 Запускаем Multiple...${NC}"
    nohup "$INSTALL_DIR/multiple-node" > "$INSTALL_DIR/output.log" 2>&1 &

    # Привязка аккаунта
    echo -e "${YELLOW}🔗 Вставьте ваш Account ID из страницы Setup:${NC}"
    read -r IDENTIFIER
    echo -e "${YELLOW}🔑 Введите PIN для ноды:${NC}"
    read -r PIN

    "$INSTALL_DIR/multiple-cli" bind --bandwidth-download 100 --identifier "$IDENTIFIER" --pin "$PIN" --storage 200 --bandwidth-upload 100

    echo -e "${GREEN}✅ Нода Multiple успешно установлена!${NC}"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}📌 Команда для проверки статуса ноды:${NC}"
    echo -e "${PURPLE}cd ~/multipleforlinux && ./multiple-cli status${NC}"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}🚀 PROFIT NODES — лови иксы на нодах${NC}"
    echo -e "${CYAN}🔗 Основной канал: https://t.me/ProfiT_Mafia${NC}"

    # Проверяем статус ноды
    "$INSTALL_DIR/multiple-cli" status
}



# Обновление ноды
function reinstal_node() {
    echo -e "${BLUE}Обновляем ноду Multiple...${NC}"
    pkill -f multiple-node
    sudo rm -rf ~/multipleforlinux multipleforlinux.tar

    install_node
    echo -e "${GREEN}Нода Multiple успешно обновлена!${NC}"
}

# Удаление ноды
function remove_node() {
    echo -e "${BLUE}Удаляем ноду Multiple...${NC}"
    pkill -f multiple-node
    sudo rm -rf ~/multipleforlinux multipleforlinux.tar
    echo -e "${GREEN}Нода Multiple успешно удалена!${NC}"
}

# Просмотр статуса
function check_status() {
    if [ -d ~/multipleforlinux ]; then
        cd ~/multipleforlinux || exit
        ./multiple-cli status
    else
        echo -e "${RED}Нода не найдена! Убедитесь, что она установлена.${NC}"
    fi
}

# Меню
function show_menu() {
    show_logo
    echo -e "${CYAN}1)${NC} 🚀${CYAN} Установить ноду${NC}"
    echo -e "${CYAN}2)${NC} 🔄${CYAN} Переустановить ноду${NC}"
    echo -e "${CYAN}3)${NC} 🗑️ ${CYAN} Удалить ноду${NC}"
    echo -e "${CYAN}4)${NC} 💻${CYAN} Проверка статуса${NC}"
    echo -e "${CYAN}5)${NC} ❌${CYAN} Выйти${NC}"

    echo -e "${YELLOW}Выберите действие:${NC}"
    read -r choice
    case $choice in
        1) install_node ;;
        2) reinstal_node ;;
        3) remove_node ;;
        4) check_status ;;
        5) echo -e "${GREEN}Выход...${NC}" ;;
        *) echo -e "${RED}Неверный выбор! Пожалуйста, выберите от 1 до 5.${NC}" ;;
    esac
}

# Запуск меню
show_menu
