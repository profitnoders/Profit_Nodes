#!/bin/bash

# === Цвета ===
CLR_INFO='\033[1;97;44m'
CLR_SUCCESS='\033[1;30;42m'
CLR_WARNING='\033[1;37;41m'
CLR_ERROR='\033[1;31;40m'
CLR_GREEN='\033[1;32m'
CLR_RESET='\033[0m'

# === Пути ===
SCRIPT_DIR="/root/auto-t3rn"
SCRIPT_NAME="auto-t3rn.py"
SCRIPT_URL="https://raw.githubusercontent.com/profitnoders/Profit_Nodes/main/$SCRIPT_NAME"
SERVICE_FILE="/etc/systemd/system/auto-t3rn.service"

# === Логотип ===
function show_logo() {
    echo -e "${CLR_INFO}   🚀 Установка auto-t3rn   ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/main/logo_new.sh | bash
}

# === Установка зависимостей ===
function install_dependencies() {
    sudo apt update

    if ! command -v python3 &> /dev/null; then
        sudo apt install -y python3 python3-venv python3-pip
    fi

    if ! command -v curl &> /dev/null; then
        sudo apt install -y curl
    fi

    mkdir -p "$SCRIPT_DIR"
    cd "$SCRIPT_DIR" || exit

    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install web3

    echo -e "${CLR_SUCCESS}✅ Зависимости и окружение готовы!${CLR_RESET}"
}

# === Установка и запуск скрипта ===
function install_and_run_script() {
    mkdir -p "$SCRIPT_DIR"
    cd "$SCRIPT_DIR" || exit

    echo -e "${CLR_INFO}⏳ Скачиваю скрипт...${CLR_RESET}"
    curl -o "$SCRIPT_NAME" "$SCRIPT_URL"

    if [[ $? -ne 0 ]]; then
        echo -e "${CLR_ERROR}❌ Ошибка при загрузке скрипта.${CLR_RESET}"
        return
    fi

    read -p "🔑 Введите приватный ключ (с 0x в начале): " PRIVATE_KEY
    sed -i "s/your_private_key/$PRIVATE_KEY/" "$SCRIPT_NAME"

    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=auto-t3rn service
After=network.target

[Service]
User=root
WorkingDirectory=$SCRIPT_DIR
ExecStart=$SCRIPT_DIR/venv/bin/python3 $SCRIPT_DIR/$SCRIPT_NAME
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl enable auto-t3rn.service
    systemctl start auto-t3rn.service

    echo -e "${CLR_SUCCESS}✅ Скрипт установлен и запущен как сервис!${CLR_RESET}"
}

# === Удаление ===
function remove_script() {
    read -p "⚠ Удалить скрипт и сервис полностью? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" ]]; then
        systemctl stop auto-t3rn.service
        systemctl disable auto-t3rn.service
        rm -rf "$SCRIPT_DIR"
        rm -f "$SERVICE_FILE"
        systemctl daemon-reload
        echo -e "${CLR_SUCCESS}✅ auto-t3rn удалён!${CLR_RESET}"
    else
        echo -e "${CLR_INFO}❎ Отмена удаления.${CLR_RESET}"
    fi
}

# === Просмотр логов ===
function show_logs() {
    echo -e "${CLR_GREEN}1) 📜 Показать последние 50 строк лога${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 🎥 Следить за логом в реальном времени${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 🔙 Назад${CLR_RESET}"
    echo -en "${CLR_INFO}Выберите действие:${CLR_RESET} "
    read -r log_choice
    case $log_choice in
        1) journalctl -u auto-t3rn.service -n 50 --no-pager ;;
        2) journalctl -u auto-t3rn.service -f ;;
        3) show_menu ;;
        *) echo -e "${CLR_WARNING}Неверный выбор. Попробуйте снова.${CLR_RESET}" && show_logs ;;
    esac
}

# === Меню ===
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) ⚙️  Установить скрипт и запустить как сервис${CLR_RESET}"
    echo -e "${CLR_GREEN}2) 🗑 Удалить скрипт и сервис${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 📜 Логи скрипта${CLR_RESET}"
    echo -e "${CLR_GREEN}4) ❌ Выйти${CLR_RESET}"
    echo -en "${CLR_INFO}Выберите действие:${CLR_RESET} "
    read -r choice
    case $choice in
        1) install_dependencies && install_and_run_script ;;
        2) remove_script ;;
        3) show_logs ;;
        4) echo -e "${CLR_ERROR}Выход...${CLR_RESET}" ;;
        *) echo -e "${CLR_WARNING}Неверный выбор. Попробуйте снова.${CLR_RESET}" && show_menu ;;
    esac
}

# === Запуск ===
show_menu
