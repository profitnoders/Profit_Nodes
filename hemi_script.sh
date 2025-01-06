#!/usr/bin/env bash

# Цветовые настройки
COLORS=(
    '\033[1;31m'  # RED
    '\033[1;32m'  # GREEN
    '\033[1;33m'  # YELLOW
    '\033[1;34m'  # BLUE
    '\033[1;35m'  # PURPLE
    '\033[1;36m'  # CYAN
    '\033[0m'     # RESET
)
RED="${COLORS[0]}"
GREEN="${COLORS[1]}"
YELLOW="${COLORS[2]}"
BLUE="${COLORS[3]}"
PURPLE="${COLORS[4]}"
CYAN="${COLORS[5]}"
NC="${COLORS[6]}"

# Проверка необходимых утилит
function check_dependencies() {
    echo -e "${YELLOW}Проверка необходимых утилит...${NC}"
    for tool in curl tar systemctl; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${RED}Утилита ${tool} не найдена. Устанавливаем...${NC}"
            sudo apt-get update
            sudo apt-get install -y "$tool"
        fi
    done
}

# Логотип
function display_logo() {
    echo -e "${GREEN}===============================${NC}"
    echo -e "${CYAN}  Добро пожаловать в скрипт установки Hemi  ${NC}"
    echo -e "${GREEN}===============================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Основное меню
function display_menu() {
    echo -e "${YELLOW}Выберите действие:${NC}"
    echo -e "${CYAN}1) Установить ноду${NC}"
    echo -e "${CYAN}2) Обновить ноду${NC}"
    echo -e "${CYAN}3) Изменить комиссию${NC}"
    echo -e "${CYAN}4) Удалить ноду${NC}"
    echo -e "${CYAN}5) Проверить логи ноды${NC}"
    echo -e "${YELLOW}Ваш выбор:${NC}"
}

function install_node() {
    echo -e "${BLUE}Начинаем установку Hemi...${NC}"
    sudo apt update && sudo apt upgrade -y
    curl -L -O https://github.com/hemilabs/heminetwork/releases/download/v0.8.0/heminetwork_v0.8.0_linux_amd64.tar.gz
    mkdir -p hemi
    tar --strip-components=1 -xzvf heminetwork_v0.8.0_linux_amd64.tar.gz -C hemi
    cd hemi || exit
    echo -e "${GREEN}Hemi установлена!${NC}"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}PROFIT NODES — лови иксы на нодах${NC}"
    echo -e "${CYAN}Основной канал: https://t.me/ProfiT_Mafia${NC}"
    sleep 1
}

# Обновление ноды
function update_node() {
    echo -e "${BLUE}Обновление Hemi...${NC}"
    rm -rf *hemi*
    install_node
    echo -e "${GREEN}Hemi обновлена!${NC}"
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}PROFIT NODES — лови иксы на нодах${NC}"
    echo -e "${CYAN}Основной канал: https://t.me/ProfiT_Mafia${NC}"
    sleep 1
}

# Изменение комиссии
function change_fee() {
    echo -e "${YELLOW}Введите новый размер комиссии (не меньше 50):${NC}"
    read -r new_fee
    if [[ $new_fee -ge 50 ]]; then
        echo "POPM_STATIC_FEE=$new_fee" > "$HOME/hemi/popmd.env"
        sudo systemctl restart hemi
        echo -e "${GREEN}Комиссия обновлена!${NC}"
    else
        echo -e "${RED}Ошибка: Комиссия должна быть не менее 50!${NC}"
    fi
    # Завершающий вывод
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}PROFIT NODES — лови иксы на нодах${NC}"
    echo -e "${CYAN}Основной канал: https://t.me/ProfiT_Mafia${NC}"
    sleep 1 
}

# Удаление ноды
function delete_node() {
    echo -e "${RED}Удаляем Hemi...${NC}"
    sudo systemctl stop hemi
    sudo systemctl disable hemi
    rm -rf /etc/systemd/system/hemi.service
    rm -rf hemi*
    sudo systemctl daemon-reload
    echo -e "${GREEN}Hemi удалена!${NC}"
    # Завершающий вывод
    echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
    echo -e "${GREEN}PROFIT NODES — лови иксы на нодах${NC}"
    echo -e "${CYAN}Основной канал: https://t.me/ProfiT_Mafia${NC}"
    sleep 1 
}

# Проверка логов
function check_logs() {
    echo -e "${CYAN}Проверяем логи Hemi...${NC}"
    sudo journalctl -u hemi -f
}

# Основной блок
check_dependencies
display_logo
display_menu

read -r choice

case $choice in
    1) install_node ;;
    2) update_node ;;
    3) change_fee ;;
    4) delete_node ;;
    5) check_logs ;;
    *) echo -e "${RED}Неверный выбор!${NC}" ;;
esac
