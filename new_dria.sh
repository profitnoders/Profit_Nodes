#!/bin/bash

# Оформление текста: цвета и фоны
CLR_INFO='\033[1;97;44m'  # Белый текст на синем фоне
CLR_SUCCESS='\033[1;30;42m'  # Зеленый текст на черном фоне
CLR_WARNING='\033[1;37;41m'  # Белый текст на красном фоне
CLR_ERROR='\033[1;31;40m'  # Красный текст на черном фоне
CLR_RESET='\033[0m'  # Сброс форматирования
CLR_GREEN='\033[0;32m' # Зеленый текст

# Функция отображения логотипа
function show_logo() {
    echo -e "${CLR_SUCCESS} Добро пожаловать в скрипт установки ноды Dria ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция установки зависимостей
function install_dependencies() {
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git make jq build-essential gcc unzip wget curl
}

# Установка ноды
function install_node() {
    echo -e "${CLR_INFO}Начинаем установку ноды Dria...${CLR_RESET}"
    install_dependencies

    # Установка новой версии лаунчера
    curl -fsSL https://dria.co/launcher | bash

    echo -e "${CLR_SUCCESS}Нода Dria успешно установлена!${CLR_RESET}"
}

# Настройка ноды
function configure_node() {
    echo -e "${CLR_INFO}Настройка параметров ноды...${CLR_RESET}"
    dkn-compute-launcher settings
}

# Запуск ноды в screen режиме
function start_node() {
    echo -e "${CLR_INFO}🚀 Запуск ноды Dria в screen сессии...${CLR_RESET}"

    # Проверяем, существует ли уже сессия с таким именем
    if screen -list | grep -q "dria_node"; then
        echo -e "${CLR_WARNING}⚠ Нода уже запущена в screen сессии 'dria_node'.${CLR_RESET}"
    else
        # Создаем новую screen-сессию и запускаем ноду внутри нее
        screen -dmS dria_node bash -c "dkn-compute-launcher start; exec bash"
        echo -e "${CLR_SUCCESS}✅ Нода Dria успешно запущена в screen сессии 'dria_node'!${CLR_RESET}"
    fi
}

# Обновление ноды
function update_node() {
    echo -e "${CLR_INFO}Обновление ноды до последней версии...${CLR_RESET}"
    dkn-compute-launcher update
    echo -e "${CLR_SUCCESS}Нода успешно обновлена!${CLR_RESET}"
}

# Проверка производительности моделей
function measure_models() {
    echo -e "${CLR_INFO}Измерение производительности моделей...${CLR_RESET}"
    dkn-compute-launcher measure
}


# Удаление ноды с подтверждением пользователя
function remove_node() {
    echo -e "${CLR_WARNING}⚠ Вы уверены, что хотите удалить ноду Dria? (y/n)${CLR_RESET}"
    read -r confirmation

    if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
        echo -e "${CLR_INFO}🚀 Удаление ноды Dria...${CLR_RESET}"
        
        # Остановка и удаление ноды
        
        screen -X -S dria_node quit
        rm -rf .dria
        
        echo -e "${CLR_SUCCESS}✅ Нода Dria успешно удалена.${CLR_RESET}"
    else
        echo -e "${CLR_INFO}❌ Удаление отменено пользователем.${CLR_RESET}"
    fi
}

# Меню выбора действий
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) ⚙️  Настроить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}3) ✅ Запустить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 🔄 Обновить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}5) 📊 Проверить производительность моделей${CLR_RESET}"
    echo -e "${CLR_GREEN}6) 🗑️  Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}7) ❌ Выйти${CLR_RESET}"
    echo -e "${CLR_INFO}Введите номер:${CLR_RESET}"
    read -r choice

    case $choice in
        1) install_node ;;
        2) configure_node ;;
        3) start_node ;;
        4) update_node ;;
        5) measure_models ;;
        6) remove_node ;;
        7) echo -e "${CLR_ERROR}Выход...${CLR_RESET}" ;;
        *) echo -e "${CLR_WARNING}Неверный выбор. Попробуйте снова.${CLR_RESET}" ;;
    esac
}

# Запуск меню
show_menu
