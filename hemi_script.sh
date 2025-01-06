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
    echo -e "${CYAN}  Добро пожаловать в скрипт установки ноды Hemi  ${NC}"
    echo -e "${GREEN}===============================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Установка необходимых пакетов
function install_dependencies() {
    echo -e "${YELLOW}Обновляем систему и устанавливаем зависимости...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl tar
}

# Установка ноды
function install_node() {
    echo -e "${BLUE}Начинаем установку Hemi...${NC}"
    install_dependencies
    curl -L -O https://github.com/hemilabs/heminetwork/releases/download/v0.8.0/heminetwork_v0.8.0_linux_amd64.tar.gz
    mkdir -p hemi
    tar --strip-components=1 -xzvf heminetwork_v0.8.0_linux_amd64.tar.gz -C hemi
    cd hemi || exit

    echo -e "${YELLOW}Создаем tBTC кошелек...${NC}"
    ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json
    cat ~/popm-address.json
    echo -e "${RED}Сохраните данные в надёжное место!${NC}"

    echo -e "${YELLOW}Введите приватный ключ от кошелька:${NC}"
    read -r PRIV_KEY
    echo -e "${YELLOW}Укажите размер комиссии (минимум 50):${NC}"
    read -r FEE

    echo "POPM_BTC_PRIVKEY=$PRIV_KEY" > popmd.env
    echo "POPM_STATIC_FEE=$FEE" >> popmd.env
    echo "POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public" >> popmd.env

    create_service
    sudo systemctl start hemi
    echo -e "${GREEN}Установка завершена! Нода запущена.${NC}"
}

# Создание systemd-сервиса
function create_service() {
    echo -e "${BLUE}Создаем сервис Hemi...${NC}"
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo "~$USERNAME")

    cat <<EOT | sudo tee /etc/systemd/system/hemi.service > /dev/null
[Unit]
Description=PopMD Service
After=network.target

[Service]
User=$USERNAME
EnvironmentFile=$HOME_DIR/hemi/popmd.env
ExecStart=$HOME_DIR/hemi/popmd
WorkingDirectory=$HOME_DIR/hemi/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

    sudo systemctl daemon-reload
    sudo systemctl enable hemi
}

# Обновление ноды
function update_node() {
    echo -e "${BLUE}Обновляем ноду Hemi...${NC}"
    sudo systemctl stop hemi
    sudo rm -rf hemi heminetwork_v0.8.0_linux_amd64.tar.gz /etc/systemd/system/hemi.service

    install_node
    echo -e "${GREEN}Нода успешно обновлена!${NC}"
}

# Изменение комиссии
function change_fee() {
    echo -e "${YELLOW}Укажите новое значение комиссии (минимум 50):${NC}"
    read -r NEW_FEE
    if [ "$NEW_FEE" -ge 50 ]; then
        sed -i "s/^POPM_STATIC_FEE=.*/POPM_STATIC_FEE=$NEW_FEE/" "$HOME/hemi/popmd.env"
        sudo systemctl restart hemi
        echo -e "${GREEN}Комиссия успешно изменена!${NC}"
    else
        echo -e "${RED}Ошибка: комиссия должна быть не меньше 50!${NC}"
    fi
}


# Удаление ноды
function remove_node() {
    echo -e "${BLUE}Удаляем ноду Hemi...${NC}"
    sudo systemctl stop hemi
    sudo systemctl disable hemi
    sudo rm -rf hemi heminetwork_v0.8.0_linux_amd64.tar.gz /etc/systemd/system/hemi.service
    sudo systemctl daemon-reload
    echo -e "${GREEN}Нода успешно удалена!${NC}"
}

# Просмотр логов
function check_logs() {
    echo -e "${BLUE}Логи ноды Hemi...${NC}"
    sudo journalctl -u hemi -f
}

# Меню
function show_menu() {
    show_logo
    echo -e "${CYAN}1) Установить ноду${NC}"
    echo -e "${CYAN}2) Обновить ноду${NC}"
    echo -e "${CYAN}3) Изменить комиссию${NC}"
    echo -e "${CYAN}4) Удалить ноду${NC}"
    echo -e "${CYAN}5) Проверка логов${NC}"
    echo -e "${CYAN}6) Выйти${NC}"

    echo -e "${YELLOW}Выберите действие:${NC}"
    read -r choice
    case $choice in
        1) install_node ;;
        2) update_node ;;
        3) change_fee ;;
        4) remove_node ;;
        5) check_logs ;;
        6) echo -e "${GREEN}Выход...${NC}" ;;
        *) echo -e "${RED}Неверный выбор!${NC}" ;;
    esac
}

# Запуск меню
show_menu
