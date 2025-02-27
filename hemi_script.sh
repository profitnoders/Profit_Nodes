#!/bin/bash

# Цвета текста с фоном
CLR_INFO='\033[1;97;44m'   # Белый текст на синем фоне
CLR_SUCCESS='\033[1;30;42m'  # Черный текст на зеленом фоне
CLR_WARNING='\033[1;37;41m'  # Белый текст на красном фоне
CLR_ERROR='\033[1;31;40m'  # Красный текст на черном фоне
CYAN='\033[1;33;46m'  # Желтый текст на голубом фоне
NC='\033[0m'  # Сброс цвета

# Логотип
function show_logo() {
    echo -e "${CLR_SUCCESS}===============================${NC}"
    echo -e "${CYAN}  Добро пожаловать в скрипт установки ноды Hemi  ${NC}"
    echo -e "${CLR_SUCCESS}===============================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Установка необходимых пакетов
function install_dependencies() {
    echo -e "${CLR_WARNING}🔄 Обновляем систему и устанавливаем зависимости...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl tar
}

# Установка ноды
function install_node() {
    echo -e "${CLR_INFO}🚀 Начинаем установку Hemi...${NC}"
    install_dependencies

    NODE_VERSION="v0.11.5"
    NODE_DIR="$HOME/hemi"
    NODE_ARCHIVE="heminetwork_${NODE_VERSION}_linux_amd64.tar.gz"
    NODE_URL="https://github.com/hemilabs/heminetwork/releases/download/${NODE_VERSION}/${NODE_ARCHIVE}"

    # Скачивание ноды
    echo -e "${CYAN}🌍 Скачиваем ноду Hemi...${NC}"
    curl -L -O "$NODE_URL"

    # Создание папки и распаковка
    rm -rf "$NODE_DIR"
    mkdir -p "$NODE_DIR"
    tar --strip-components=1 -xzvf "$NODE_ARCHIVE" -C "$NODE_DIR"
    cd "$NODE_DIR" || exit

    # Генерация кошелька
    echo -e "${CLR_WARNING}🔑 Создаем tBTC кошелек...${NC}"
    ./keygen -secp256k1 -json -net="testnet" > "$HOME/popm-address.json"
    cat "$HOME/popm-address.json"
    echo -e "${CLR_ERROR}⚠️ Внимание! Сохраните данные в надежное место!${NC}"

    # Запрос приватного ключа и комиссии
    echo -e "${CLR_WARNING}🔑 Вставьте ваш приватный ключ от кошелька:${NC}"
    read -r PRIVATE_KEY
    echo -e "${CLR_WARNING}💰 Укажите размер комиссии (например, 2000):${NC}"
    read -r COUNT_FEE

    # Создание файла конфигурации
    echo "POPM_BTC_PRIVKEY=$PRIVATE_KEY" > popmd.env
    echo "POPM_STATIC_FEE=$COUNT_FEE" >> popmd.env
    echo "POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public" >> popmd.env

    create_service
    sudo systemctl start hemi

    echo -e "${CLR_SUCCESS}✅ Установка завершена! Нода успешно запущена.${NC}"
}

# Создание systemd-сервиса
function create_service() {
    echo -e "${CYAN}🔧 Создаем systemd-сервис Hemi...${NC}"
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo "~$USERNAME")

    sudo tee /etc/systemd/system/hemi.service > /dev/null <<EOT
[Unit]
Description=Hemi Node Service
After=network.target

[Service]
User=$USERNAME
EnvironmentFile=$HOME_DIR/hemi/popmd.env
ExecStart=$HOME_DIR/hemi/popmd
WorkingDirectory=$HOME_DIR/hemi/
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOT

    sudo systemctl daemon-reload
    sudo systemctl enable hemi
}

# Обновление ноды
function update_node() {
    echo -e "${CLR_INFO}🔄 Обновляем ноду Hemi...${NC}"
    sudo systemctl stop hemi
    rm -rf "$HOME/hemi" heminetwork_*.tar.gz /etc/systemd/system/hemi.service

    install_node
    echo -e "${CLR_SUCCESS}✅ Нода успешно обновлена!${NC}"
}

# Изменение комиссии
function change_fee() {
    echo -e "${CLR_WARNING}💰 Укажите новый размер комиссии:${NC}"
    read -r NEW_FEE
    if [[ "$NEW_FEE" =~ ^[0-9]+$ ]] && [ "$NEW_FEE" -ge 50 ]; then
        sed -i "s/^POPM_STATIC_FEE=.*/POPM_STATIC_FEE=$NEW_FEE/" "$HOME/hemi/popmd.env"
        sudo systemctl restart hemi
        echo -e "${CLR_SUCCESS}✅ Комиссия успешно изменена!${NC}"
    else
        echo -e "${CLR_ERROR}❌ Ошибка: комиссия должна быть числом и не менее 50!${NC}"
    fi
}

# Удаление ноды
function remove_node() {
    echo -e "${CYAN}🗑️ Удаляем ноду Hemi...${NC}"
    sudo systemctl stop hemi
    sudo systemctl disable hemi
    rm -rf "$HOME/hemi" heminetwork_*.tar.gz /etc/systemd/system/hemi.service
    sudo systemctl daemon-reload
    echo -e "${CLR_SUCCESS}✅ Нода успешно удалена!${NC}"
}

# Просмотр логов
function check_logs() {
    echo -e "${CLR_INFO}📜 Логи ноды Hemi...${NC}"
    sudo journalctl -u hemi -f
}

# Просмотр статуса
function check_status() {
    echo -e "${CYAN}📌 Проверяем статус ноды...${NC}"
    sudo systemctl status hemi --no-pager
}

# Меню
function show_menu() {
    show_logo
    echo -e "${CYAN}📌 Выберите действие:${NC}"
    echo -e "${CYAN}1) 🚀 Установить ноду${NC}"
    echo -e "${CYAN}2) 🔄 Обновить ноду${NC}"
    echo -e "${CYAN}3) ⚙️ Изменить комиссию${NC}"
    echo -e "${CYAN}4) 🗑️ Удалить ноду${NC}"
    echo -e "${CYAN}5) 💻 Проверить логи${NC}"
    echo -e "${CYAN}6) 📊 Проверить статус${NC}"
    echo -e "${CYAN}7) ❌ Выйти${NC}"

    echo -e "${CLR_WARNING}Введите номер действия:${NC}"
    read -r choice
    case $choice in
        1) install_node ;;
        2) update_node ;;
        3) change_fee ;;
        4) remove_node ;;
        5) check_logs ;;
        6) check_status ;;
        7) echo -e "${CLR_SUCCESS}Выход...${NC}" && exit 0 ;;
        *) echo -e "${CLR_ERROR}❌ Ошибка: Неверный ввод! Попробуйте снова.${NC}" ;;
    esac
}

# Запуск меню
show_menu
