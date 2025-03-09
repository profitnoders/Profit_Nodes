#!/bin/bash

# Цвета
CLR_INFO='\033[1;97;44m'
CLR_SUCCESS='\033[1;30;42m'
CLR_WARNING='\033[1;37;41m'
CLR_ERROR='\033[1;31;40m'
CLR_RESET='\033[0m'
CLR_GREEN='\033[0;32m'

# Функция логотипа
function show_logo() {
    echo -e "${CLR_INFO} Добро пожаловать в скрипт управления InitVerse Mainnet ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция установки зависимостей
function install_dependencies() {
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y wget curl
}

# Установка ноды InitVerse
function install_node() {
    install_dependencies

    mkdir -p $HOME/initverse
    cd $HOME/initverse
    wget https://github.com/Project-InitVerse/ini-miner/releases/download/v1.0.0/iniminer-linux-x64
    chmod +x iniminer-linux-x64

    echo -e "${CLR_WARNING}Введите имя для майнера:${CLR_RESET}"
    read MAINER_NAME
    echo -e "${CLR_WARNING}Вставьте EVM-адрес кошелька:${CLR_RESET}"
    read WALLET
    echo -e "${CLR_WARNING}Сколько ядер CPU использовать? (от 2 до 8):${CLR_RESET}"
    read CPU_CORES

    if [[ $CPU_CORES -lt 2 || $CPU_CORES -gt 8 ]]; then
        echo -e "${CLR_ERROR}Ошибка: количество ядер должно быть от 2 до 8!${CLR_RESET}"
        exit 1
    fi

    # Выбор пула
    select_pool

    # Запись конфигурации в .env
    echo "WALLET=$WALLET" > "$HOME/initverse/.env"
    echo "MAINER_NAME=$MAINER_NAME" >> "$HOME/initverse/.env"
    echo "CPU_CORES=$CPU_CORES" >> "$HOME/initverse/.env"
    echo "POOL_URL=$POOL_URL" >> "$HOME/initverse/.env"
    echo "POOL_PORT=$POOL_PORT" >> "$HOME/initverse/.env"

    # Перечитываем переменные
    source $HOME/initverse/.env

    # Создаём systemd-сервис
    create_service

    # Запуск сервиса
    sudo systemctl daemon-reload
    sudo systemctl enable initverse
    sudo systemctl restart initverse

    echo -e "${CLR_SUCCESS}Нода InitVerse установлена и запущена на пуле $POOL_URL:$POOL_PORT с $CPU_CORES ядрами!${CLR_RESET}"
}

# Функция выбора пула
function select_pool() {
    echo -e "${CLR_WARNING}Выберите пул для майнинга:${CLR_RESET}"
    echo -e "${CLR_GREEN}1) Pool A (pool-a.yatespool.com:31588)${CLR_RESET}"
    echo -e "${CLR_GREEN}2) Pool B (pool-b.yatespool.com:32488)${CLR_RESET}"
    echo -e "${CLR_GREEN}3) Pool C (pool-c.yatespool.com:31189)${CLR_RESET}"

    read -p "Введите номер пула (1/2/3): " POOL_CHOICE

    case $POOL_CHOICE in
        1) POOL_URL="pool-a.yatespool.com"; POOL_PORT="31588";;
        2) POOL_URL="pool-b.yatespool.com"; POOL_PORT="32488";;
        3) POOL_URL="pool-c.yatespool.com"; POOL_PORT="31189";;
        *) echo -e "${CLR_ERROR}Ошибка: неверный выбор пула!${CLR_RESET}"; exit 1;;
    esac
}

# Функция создания systemd сервиса
function create_service() {
    source $HOME/initverse/.env

    # Формируем аргументы для CPU
    CPU_DEVICES=""
    for ((i=0; i<CPU_CORES; i++))
    do
      CPU_DEVICES+=" --cpu-devices $i"
    done

    # Записываем новый сервис
    sudo bash -c "cat <<EOT > /etc/systemd/system/initverse.service
[Unit]
Description=InitVerse Mainnet Miner Service
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$HOME/initverse
ExecStart=/bin/bash -c 'source $HOME/initverse/.env && $HOME/initverse/iniminer-linux-x64 --pool stratum+tcp://$WALLET.$MAINER_NAME@$POOL_URL:$POOL_PORT$CPU_DEVICES'
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"
}

# Функция запуска майнера
function start_miner() {
    sudo systemctl start initverse
    echo -e "${CLR_SUCCESS}Майнер запущен!${CLR_RESET}"
}

# Функция остановки майнера
function stop_miner() {
    sudo systemctl stop initverse
    echo -e "${CLR_WARNING}Майнер остановлен.${CLR_RESET}"
}

# Функция изменения количества ядер
function change_cpu_cores() {
    echo -e "${CLR_WARNING}Введите новое количество ядер (от 2 до 8):${CLR_RESET}"
    read NEW_CPU_CORES

    if [[ $NEW_CPU_CORES -lt 2 || $NEW_CPU_CORES -gt 8 ]]; then
        echo -e "${CLR_ERROR}Ошибка: количество ядер должно быть от 2 до 8!${CLR_RESET}"
        exit 1
    fi

    # Обновляем файл .env
    sed -i "s/^CPU_CORES=.*/CPU_CORES=$NEW_CPU_CORES/" $HOME/initverse/.env

    # Перезапускаем сервис
    create_service
    sudo systemctl daemon-reload
    sudo systemctl restart initverse

    echo -e "${CLR_SUCCESS}Количество ядер изменено на $NEW_CPU_CORES!${CLR_RESET}"
}

# Функция изменения пула
function change_pool() {
    echo -e "${CLR_WARNING}Выберите новый пул:${CLR_RESET}"
    select_pool

    # Обновляем .env с новым пулом
    sed -i "s|^POOL_URL=.*|POOL_URL=$POOL_URL|" $HOME/initverse/.env
    sed -i "s|^POOL_PORT=.*|POOL_PORT=$POOL_PORT|" $HOME/initverse/.env

    # Перезапускаем сервис
    create_service
    sudo systemctl daemon-reload
    sudo systemctl restart initverse

    echo -e "${CLR_SUCCESS}Пул изменён на $POOL_URL:$POOL_PORT!${CLR_RESET}"
}

# Просмотр логов
function view_logs() {
    sudo journalctl -fu initverse.service
}

# Удаление ноды
function remove_node() {
    echo -e "${CLR_WARNING}Вы уверены, что хотите удалить ноду? (y/n)${CLR_RESET}"
    read -r CONFIRMATION
    if [[ "$CONFIRMATION" == "y" ]]; then
        sudo systemctl stop initverse
        sudo systemctl disable initverse
        sudo rm /etc/systemd/system/initverse.service
        sudo systemctl daemon-reload
        rm -rf $HOME/initverse
        echo -e "${CLR_WARNING}Нода удалена.${CLR_RESET}"
    else
        echo -e "${CLR_SUCCESS}Операция отменена.${CLR_RESET}"
    fi
}

# Главное меню
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}2) ▶ Запустить майнер${CLR_RESET}"
    echo -e "${CLR_GREEN}3) ⏹ Остановить майнер${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 🔄 Изменить количество ядер${CLR_RESET}"
    echo -e "${CLR_GREEN}5) 🌍 Сменить пул${CLR_RESET}"
    echo -e "${CLR_GREEN}6) 📜 Просмотр логов${CLR_RESET}"
    echo -e "${CLR_GREEN}7) 🗑️ Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}8) ❌ Выйти${CLR_RESET}"

    read -p "Выберите номер действия: " choice

    case $choice in
        1) install_node ;;
        2) start_miner ;;
        3) stop_miner ;;
        4) change_cpu_cores ;;
        5) change_pool ;;
        6) view_logs ;;
        7) remove_node ;;
        8) exit 0 ;;
        *) echo -e "${CLR_WARNING}Неверный выбор.${CLR_RESET}" && show_menu ;;
    esac
}

show_menu




