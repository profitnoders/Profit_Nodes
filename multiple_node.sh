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
    echo -e "${BLUE}🚀 Запуск установки ноды Multiple...${NC}"
    install_dependencies

    # Определяем архитектуру системы
    echo -e "${BLUE}🔍 Определение архитектуры системы...${NC}"
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        CLIENT_URL="https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/MultipleForLinux.tar"
    elif [[ "$ARCH" == "aarch64" ]]; then
        CLIENT_URL="https://mdeck-download.s3.us-east-1.amazonaws.com/client/linux/MultipleForLinux.tar"
    else
        echo -e "${RED}❌ Ошибка: Архитектура $ARCH не поддерживается!${NC}"
        exit 1
    fi

    # Скачиваем архив с клиентом
    echo -e "${BLUE}🌍 Загружаем установочный файл...${NC}"
    wget -O /root/MultipleForLinux.tar "$CLIENT_URL"

    # Распаковываем в нужную директорию
    echo -e "${BLUE}📦 Извлечение файлов...${NC}"
    tar -xvf /root/MultipleForLinux.tar -C /root/

    # Проверяем, создана ли папка
    INSTALL_DIR="/root/MultipleForLinux"
    if [[ ! -d "$INSTALL_DIR" ]]; then
        echo -e "${RED}❌ Ошибка: Папка $INSTALL_DIR не была создана!${NC}"
        exit 1
    fi

    # Переходим в директорию клиента
    cd "$INSTALL_DIR" || exit

    # Проверяем наличие файлов
    if [[ ! -f "./multiple-cli" ]] || [[ ! -f "./multiple-node" ]]; then
        echo -e "${RED}❌ Ошибка: Не найдены файлы multiple-cli или multiple-node!${NC}"
        ls -lah "$INSTALL_DIR"  # Показываем содержимое для диагностики
        exit 1
    fi

    # Назначаем права на выполнение
    echo -e "${BLUE}🔑 Устанавливаем разрешения на выполнение...${NC}"
    chmod +x ./multiple-cli
    chmod +x ./multiple-node

    # Добавляем путь к переменным окружения
    echo -e "${BLUE}🔗 Добавляем директорию в PATH...${NC}"
    echo "export PATH=\$PATH:$INSTALL_DIR" >> ~/.bash_profile
    source ~/.bash_profile

    # Запуск ноды
    echo -e "${BLUE}🚀 Запуск ноды Multiple...${NC}"
    nohup ./multiple-node > output.log 2>&1 &

    # Привязка аккаунта
    echo -e "${YELLOW}🔹 Введите ваш Account ID:${NC}"
    read -r IDENTIFIER
    echo -e "${YELLOW}🔑 Введите PIN-код:${NC}"
    read -r PIN

    echo -e "${BLUE}🔗 Привязываем аккаунт...${NC}"
    ./multiple-cli bind --bandwidth-download 100 --identifier "$IDENTIFIER" --pin "$PIN" --storage 200 --bandwidth-upload 100

    echo -e "${GREEN}✅ Установка завершена! Нода успешно запущена.${NC}"
    echo -e "${PURPLE}-------------------------------------------------${NC}"
    echo -e "${YELLOW}📌 Проверить статус ноды можно командой:${NC}"
    echo -e "${PURPLE}cd $INSTALL_DIR && ./multiple-cli status${NC}"
    echo -e "${PURPLE}-------------------------------------------------${NC}"
    echo -e "${GREEN}🚀 PROFIT NODES — забирай дропы первыми!${NC}"
    echo -e "${CYAN}🔗 Подключайся к каналу: https://t.me/ProfiT_Mafia${NC}"

    # Проверка статуса ноды
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
    sudo rm -rf ~/multipleforlinux multipleforlinux.tar
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
