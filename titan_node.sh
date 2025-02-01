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
    echo -e "${CLR_INFO}          Установочный скрипт для Titan Network           ${CLR_RESET}"
    echo -e "${CLR_SUCCESS}**********************************************************${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция подготовки окружения: установка пакетов и зависимостей
function install_dependencies() {
    echo -e "${CLR_WARNING}🔄 Проверяем и устанавливаем необходимые зависимости...${CLR_RESET}"
    sudo apt update -y
    sudo apt install -y curl git jq lz4 build-essential unzip docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
}

# Функция развертывания узла Titan Network
function install_node() {
    echo -e "${CLR_INFO}🚀 Запускаем процесс установки Titan Network...${CLR_RESET}"
    
    INSTALL_DIR="$HOME/titan-network"
    CONFIG_FILE="$INSTALL_DIR/titan.env"
    
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR" || exit
    
    echo -e "${CLR_WARNING}🔑 Введите ваш идентификационный код Titan:${CLR_RESET}"
    read -r IDENTITY_CODE
    
    echo "TITAN_IDENTITY_CODE=$IDENTITY_CODE" > "$CONFIG_FILE"
    
    docker pull nezha123/titan-edge
    docker run --name titan --network=host -d -v ~/.titanedge:/root/.titanedge --env-file "$CONFIG_FILE" nezha123/titan-edge
    
    echo -e "${CLR_SUCCESS}✅ Установка завершена! Узел успешно запущен.${CLR_RESET}"
}

# Функция обновления ПО узла Titan
function update_node() {
    echo -e "${CLR_INFO}🔄 Обновление ноды Titan Network...${CLR_RESET}"
    
    docker stop titan
    docker rm titan
    docker pull nezha123/titan-edge
    docker run --name titan --network=host -d -v ~/.titanedge:/root/.titanedge --env-file "$HOME/titan-network/titan.env" nezha123/titan-edge
    
    echo -e "${CLR_SUCCESS}✅ Обновление завершено!${CLR_RESET}"
}

# Функция просмотра журнала работы узла
function view_logs() {
    echo -e "${CLR_INFO}📜 Отображение логов узла...${CLR_RESET}"
    docker logs -f titan
}

# Функция перезапуска сервиса ноды
function restart_node() {
    echo -e "${CLR_WARNING}🔄 Перезапускаем ноду Titan...${CLR_RESET}"
    docker restart titan
    sleep 2
    docker logs -f titan
}

# Функция удаления узла и всех связанных данных
function remove_node() {
    echo -e "${CLR_ERROR}⚠️ ВНИМАНИЕ: Удаление узла Titan Network!${CLR_RESET}"
    docker stop titan
    docker rm titan
    docker rmi nezha123/titan-edge
    rm -rf "$HOME/titan-network"
    echo -e "${CLR_SUCCESS}✅ Узел успешно удален!${CLR_RESET}"
}

# Функция отображения меню действий для пользователя
function show_menu() {
    show_logo
    echo -e "${CLR_WARNING}📌 Выберите нужное действие:${CLR_RESET}"
    echo -e "${CLR_INFO}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_INFO}2) 🔄 Перезапустить ноду${CLR_RESET}"
    echo -e "${CLR_INFO}3) 🔄 Обновить ноду${CLR_RESET}"
    echo -e "${CLR_INFO}4) 📜 Просмотреть логи${CLR_RESET}"
    echo -e "${CLR_INFO}5) 🗑️  Удалить ноду${CLR_RESET}"
    echo -e "${CLR_INFO}6) ❌ Выйти${CLR_RESET}"
    read -p "Введите номер действия: " choice
    
    case $choice in
        1) install_dependencies; install_node ;;
        2) restart_node ;;
        3) update_node ;;
        4) view_logs ;;
        5) remove_node ;;
        6) exit 0 ;;
        *) echo -e "${CLR_ERROR}❌ Ошибка: Некорректный выбор! Попробуйте снова.${CLR_RESET}" ;;
    esac
}

# Запуск скрипта
show_menu
