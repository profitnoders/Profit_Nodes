#!/bin/bash

# Оформление текста: цвета и фоны
CLR_INFO='\033[1;97;44m'  # Белый текст на синем фоне
CLR_SUCCESS='\033[1;97;42m'  # Зеленый текст на черном фоне
CLR_ERROR='\033[1;97;41m'  # Красный текст на черном фоне
CLR_RESET='\033[0m'  # Сброс форматирования

SERVICE_FILE="/etc/systemd/system/aios.service"
PRIVATE_KEY_FILE="$HOME/.aios/private_key.pem"

show_logo() {
    echo -e "${CLR_INFO} Добро пожаловать в скрипт настройки сервера Profit Nodes ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

install_node() {
    echo -e "${CLR_INFO}▶ Обновление системы и установка зависимостей...${CLR_RESET}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y mc git netcat net-tools unzip lz4 jq build-essential protobuf-compiler ncdu tmux make cmake pkg-config libssl-dev clang bc

    echo -e "${CLR_INFO}▶ Установка Hyperspace...${CLR_RESET}"
    curl -sSfL https://download.hyper.space/api/install | bash
    sleep 5
    source "$HOME/.bashrc"

    if [ -f "$SERVICE_FILE" ]; then
        echo -e "${CLR_INFO}▶ Найден старый systemd-сервис. Удаляем...${CLR_RESET}"
        sudo systemctl stop aios || true
        sudo systemctl disable aios || true
        sudo rm -f "$SERVICE_FILE"
        sudo systemctl daemon-reload
        sleep 5
    fi

    echo -e "${CLR_INFO}▶ Введите ваш PRIVATE_KEY (PEM формат):${CLR_RESET}"
    read -r PRIVATE_KEY
    mkdir -p "$HOME/.aios"
    echo "$PRIVATE_KEY" > "$PRIVATE_KEY_FILE"

    echo -e "${CLR_INFO}▶ Создание systemd-сервиса...${CLR_RESET}"
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)

    sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Hyperspace Aios Node
After=network-online.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/.aios/aios-cli start --connect
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable aios
    sudo systemctl start aios

    echo -e "${CLR_INFO}▶ Добавляем модели...${CLR_RESET}"
    $HOME/.aios/aios-cli models add hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf
    $HOME/.aios/aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf

    echo -e "${CLR_INFO}▶ Вход в Hive...${CLR_RESET}"
    $HOME/.aios/aios-cli hive import-keys "$PRIVATE_KEY_FILE"
    sleep 5
    $HOME/.aios/aios-cli hive login
    sleep 5
    $HOME/.aios/aios-cli hive select-tier 5
    sleep 5
    $HOME/.aios/aios-cli hive select-tier 3

    echo -e "${CLR_SUCCESS}✅ Установка завершена!${CLR_RESET}"
    journalctl -n 100 -f -u aios -o cat
}

restart_node() {
    echo -e "${CLR_INFO}Перезапускаем Hyperspace Node...${CLR_RESET}"
    sudo systemctl stop aios || true
    sudo systemctl disable aios || true
    sudo rm -f "$SERVICE_FILE"
    sudo systemctl daemon-reload

    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)

    sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Hyperspace Aios Node
After=network-online.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/.aios/aios-cli start --connect
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable aios
    sudo systemctl restart aios
    echo -e "${CLR_SUCCESS}✅ Нода перезапущена!${CLR_RESET}"
}

show_logs() {
    echo -e "${CLR_INFO}▶ Последние логи ноды...${CLR_RESET}"
    journalctl -n 100 -f -u aios -o cat
}

show_keys() {
    echo -e "${CLR_INFO}▶ Вывод Hive ID...${CLR_RESET}"
    $HOME/.aios/aios-cli hive whoami
}

show_points() {
    echo -e "${CLR_INFO}▶ Текущие поинты...${CLR_RESET}"
    $HOME/.aios/aios-cli hive points
}

delete_node() {
    echo -e "${CLR_ERROR}▶ Удаление Hyperspace Node...${CLR_RESET}"
    sudo systemctl stop aios || true
    sudo systemctl disable aios || true
    sudo rm -f "$SERVICE_FILE"
    rm -rf "$HOME/.aios"
    rm -rf "$HOME/.cache/hyperspace"
    rm -rf "$HOME/.config/hyperspace"
    sudo systemctl daemon-reload
    echo -e "${CLR_ERROR}Удалено успешно!${CLR_RESET}"
}

show_menu() {
        show_logo
        echo -e "${CLR_INFO}Выберите действие:${CLR_RESET}"
        echo -e "${CLR_SUCCESS}1) Установить ноду${CLR_RESET}"
        echo -e "${CLR_SUCCESS}2) Перезапустить ноду${CLR_RESET}"
        echo -e "${CLR_SUCCESS}3) Показать логи${CLR_RESET}"
        echo -e "${CLR_SUCCESS}4) Показать Hive ID${CLR_RESET}"
        echo -e "${CLR_SUCCESS}5) Показать поинты${CLR_RESET}"
        echo -e "${CLR_ERROR}6) Удалить ноду${CLR_RESET}"
        echo -e "${CLR_ERROR}7) Выход${CLR_RESET}"

        read -p "Введите номер действия: " choice

        case $choice in
            1) install_node ;;
            2) restart_node ;;
            3) show_logs ;;
            4) show_keys ;;
            5) show_points ;;
            6) delete_node ;;
            7) exit 0 ;;
            *) echo -e "${CLR_ERROR}Неверный выбор!${CLR_RESET}" ;;
        esac
}

show_menu
