#!/bin/bash

# Цвета оформления
CLR_SUCCESS='\033[1;32m'  # Зеленый
CLR_INFO='\033[1;34m'  # Синий
CLR_WARNING='\033[1;33m'  # Желтый
CLR_ERROR='\033[1;31m'  # Красный
CLR_RESET='\033[0m'  # Сброс цвета

# Функция вывода логотипа
function show_logo() {
    echo -e "${CLR_INFO}     Добро пожаловать в установщик ноды LayerEdge!     ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция установки ноды
function install_node() {
    echo -e "${CLR_INFO}▶ Обновление системы и установка зависимостей...${CLR_RESET}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y screen git curl build-essential pkg-config libssl-dev jq

    echo -e "${CLR_INFO}▶ Установка Go 1.18+...${CLR_RESET}"
    if ! command -v go &> /dev/null; then
        curl -OL https://golang.org/dl/go1.18.10.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf go1.18.10.linux-amd64.tar.gz
        rm go1.18.10.linux-amd64.tar.gz
        echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
        source ~/.bashrc
    fi

    echo -e "${CLR_INFO}▶ Установка Rust 1.81.0+...${CLR_RESET}"
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
    fi

    echo -e "${CLR_INFO}▶ Установка Risc0 Toolchain...${CLR_RESET}"
    curl -L https://risczero.com/install | bash && rzup install

    echo -e "${CLR_INFO}▶ Клонирование репозитория Light Node...${CLR_RESET}"
    git clone https://github.com/Layer-Edge/light-node.git $HOME/light-node
    cd $HOME/light-node

    echo -e "${CLR_INFO}▶ Сборка Light Node...${CLR_RESET}"
    go build

    echo -e "${CLR_INFO}▶ Настройка переменных окружения...${CLR_RESET}"
    cat <<EOF > $HOME/light-node/.env
export GRPC_URL=34.31.74.109:9090
export CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
export ZK_PROVER_URL=http://127.0.0.1:3001
export API_REQUEST_TIMEOUT=100
export POINTS_API=https://light-node.layeredge.io
export PRIVATE_KEY='cli-node-private-key'
EOF

    echo -e "${CLR_INFO}▶ Настройка systemd-сервиса...${CLR_RESET}"
    sudo bash -c "cat <<EOT > /etc/systemd/system/layeredge-merkle.service
[Unit]
Description=LayerEdge Merkle Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/light-node/risc0-merkle-service
ExecStart=cargo run
Restart=always
RestartSec=5
LimitNOFILE=65536
StandardOutput=journal
StandardError=journal
SyslogIdentifier=layeredge-merkle

[Install]
WantedBy=multi-user.target
EOT"

    sudo bash -c "cat <<EOT > /etc/systemd/system/layeredge-lightnode.service
[Unit]
Description=LayerEdge Light Node
After=network.target layeredge-merkle.service
Requires=layeredge-merkle.service

[Service]
User=$USER
WorkingDirectory=$HOME/light-node
EnvironmentFile=$HOME/light-node/.env
ExecStart=$HOME/light-node/light-node
Restart=always
RestartSec=5
LimitNOFILE=65536
StandardOutput=journal
StandardError=journal
SyslogIdentifier=layeredge-lightnode

[Install]
WantedBy=multi-user.target
EOT"

    echo -e "${CLR_INFO}▶ Запуск Merkle Service и Light Node...${CLR_RESET}"
    sudo systemctl daemon-reload
    sudo systemctl enable layeredge-merkle layeredge-lightnode
    sudo systemctl start layeredge-merkle
    sleep 10
    sudo systemctl start layeredge-lightnode

    echo -e "${CLR_SUCCESS}✅ Установка завершена! Нода LayerEdge запущена.${CLR_RESET}"
    echo -e "${CLR_INFO}▶ Просмотр логов: sudo journalctl -u layeredge-lightnode -f${CLR_RESET}"
}

# Функция запуска ноды
function start_node() {
    echo -e "${CLR_INFO}▶ Запуск LayerEdge Light Node...${CLR_RESET}"
    sudo systemctl start layeredge-merkle
    sleep 10
    sudo systemctl start layeredge-lightnode
    echo -e "${CLR_SUCCESS}✅ Нода успешно запущена.${CLR_RESET}"
}

# Функция остановки ноды
function stop_node() {
    echo -e "${CLR_INFO}▶ Остановка LayerEdge Light Node...${CLR_RESET}"
    sudo systemctl stop layeredge-lightnode
    sudo systemctl stop layeredge-merkle
    echo -e "${CLR_SUCCESS}✅ Нода остановлена.${CLR_RESET}"
}

# Функция перезапуска ноды
function restart_node() {
    echo -e "${CLR_INFO}▶ Перезапуск LayerEdge Light Node...${CLR_RESET}"
    stop_node
    start_node
}

# Функция вывода логов ноды
function logs_node() {
    echo -e "${CLR_INFO}▶ Логи ноды t3rn-executor...${CLR_RESET}"
    sudo journalctl -u layeredge-lightnode -f
}

# Функция удаления ноды (с подтверждением)
function remove_node() {
    echo -e "${CLR_WARNING}⚠ Вы уверены, что хотите удалить ноду LayerEdge? (y/n)${CLR_RESET}"
    read -p "Введите y для подтверждения или n для отмены: " confirmation
    if [[ $confirmation == "y" || $confirmation == "Y" ]]; then
        echo -e "${CLR_INFO}▶ Остановка и удаление ноды...${CLR_RESET}"
        stop_node
        sudo systemctl disable layeredge-merkle layeredge-lightnode
        sudo rm -rf $HOME/light-node /etc/systemd/system/layeredge-merkle.service /etc/systemd/system/layeredge-lightnode.service
        echo -e "${CLR_SUCCESS}✅ Нода успешно удалена.${CLR_RESET}"
    else
        echo -e "${CLR_INFO}▶ Удаление отменено.${CLR_RESET}"
    fi
}

# Функция вывода меню
function show_menu() {
    show_logo
    echo -e "${CLR_INFO}Выберите действие:${CLR_RESET}"
    echo -e "${CLR_SUCCESS}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}2) ▶ Запустить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}3) 🔄 Перезапустить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}4) 📜 Показать логи ноды${CLR_RESET}"
    echo -e "${CLR_WARNING}5) 🗑 Удалить ноду${CLR_RESET}"
    echo -e "${CLR_ERROR}5) ❌ Выйти${CLR_RESET}"

    read -p "Введите номер действия: " choice
    case $choice in
        1) install_node ;;
        2) start_node ;;
        3) restart_node ;;
        4) logs_node ;;
        4) remove_node ;;
        5) echo -e "${CLR_ERROR}Выход...${CLR_RESET}" ;;
        *) echo -e "${CLR_WARNING}Неверный ввод, попробуйте снова.${CLR_RESET}" ;;
    esac
}

# Запуск меню
show_menu
