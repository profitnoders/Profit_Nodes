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

# Функция установки ноды Multiple
function install_node() {
    echo -e "${BLUE}🚀 Начинаем установку ноды Multiple...${NC}"

    # Определяем архитектуру системы
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" || "$ARCH" == "aarch64" ]]; then
        CLIENT_URL="https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/MultipleForLinux.tar"
    else
        echo -e "${RED}❌ Неподдерживаемая архитектура системы: $ARCH${NC}"
        exit 1
    fi

    # Скачиваем клиент
    echo -e "${BLUE}🌍 Скачиваем клиент с $CLIENT_URL...${NC}"
    wget -O multipleforlinux.tar "$CLIENT_URL"

    # Распаковываем архив
    echo -e "${BLUE}📦 Распаковываем файлы...${NC}"
    tar -xvf multipleforlinux.tar

    # Выдача разрешений на выполнение
    echo -e "${BLUE}🔑 Выдаем права на выполнение...${NC}"
    chmod +x MultipleForLinux/multiple-cli
    chmod +x MultipleForLinux/multiple-node


    # Настраиваем PATH, чтобы команды работали глобально
    echo -e "${BLUE}🔧 Настраиваем окружение...${NC}"
    echo "export PATH=\$PATH:$(pwd)" >> ~/.bashrc
    source ~/.bashrc

    # Назначаем права для папки
    echo -e "${BLUE}🛠️ Назначаем права для папки...${NC}"
    chmod -R 777 MultipleForLinux

    # Запускаем ноду
    echo -e "${BLUE}🚀 Запускаем Multiple Node...${NC}"
    nohup ./multiple-node > output.log 2>&1 &

    # Привязка аккаунта
    echo -e "${YELLOW}🔗 Вставьте ваш Account ID из страницы Setup:${NC}"
    read -r IDENTIFIER
    echo -e "${YELLOW}🔑 Введите ваш PIN:${NC}"
    read -r PIN

    # Выполняем привязку аккаунта
    echo -e "${BLUE}🔗 Привязываем аккаунт...${NC}"
    ./multiple-cli bind --bandwidth-download 100 --identifier "$IDENTIFIER" --pin "$PIN" --storage 200 --bandwidth-upload 100

    echo -e "${GREEN}✅ Нода Multiple успешно установлена и запущена!${NC}"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}📌 Команда для проверки статуса ноды:${NC}"
    echo -e "${PURPLE}./multiple-cli status${NC}"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}🚀 PROFIT NODES — лови иксы на нодах${NC}"
    echo -e "${CYAN}🔗 Основной канал: https://t.me/ProfiT_Mafia${NC}"

    # Проверяем статус ноды
    ./multiple-cli status
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
    sudo rm -rf ~/MultipleForLinux multipleforlinux.tar
    rm -rf multiple_node.sh
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
