#!/bin/bash

# Цвета оформления
CLR_SUCCESS='\033[1;32m' 
CLR_INFO='\033[1;34m'  
CLR_WARNING='\033[1;33m'  
CLR_ERROR='\033[1;31m'  
CLR_RESET='\033[0m'  

function show_logo() {
    echo -e "${CLR_INFO}     Добро пожаловать в скрипт управления нодой t3rn v.2    ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

function install_node() {
    show_logo
    echo -e "${CLR_INFO}▶ Обновление системы и установка зависимостей...${CLR_RESET}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y wget curl tar systemd

    echo -e "${CLR_INFO}▶ Создание директории t3rn...${CLR_RESET}"
    mkdir -p $HOME/t3rn && cd $HOME/t3rn

    echo -e "${CLR_INFO}▶ Загрузка executor...${CLR_RESET}"
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    wget https://github.com/t3rn/executor-release/releases/download/${LATEST_VERSION}/executor-linux-${LATEST_VERSION}.tar.gz

    echo -e "${CLR_INFO}▶ Распаковка executor...${CLR_RESET}"
    tar -xzf executor-linux-*.tar.gz
    cd executor/executor/bin

    echo -e "${CLR_INFO}▶ Создание конфигурационного файла .t3rn...${CLR_RESET}"
    CONFIG_FILE="$HOME/t3rn/executor/executor/bin/.t3rn"

    cat <<EOF > $CONFIG_FILE
ENVIRONMENT=testnet
LOG_LEVEL=debug
LOG_PRETTY=false
EXECUTOR_PROCESS_BIDS_ENABLED=true
EXECUTOR_PROCESS_ORDERS_ENABLED=true
EXECUTOR_PROCESS_CLAIMS_ENABLED=true
EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
EXECUTOR_MAX_L3_GAS_PRICE=100
ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn,blast-sepolia,unichain-sepolia'

RPC_ENDPOINTS='{
    "l2rn": ["https://t3rn-b2n.blockpi.network/v1/rpc/public", "https://b2n.rpc.caldera.xyz/http"],
    "arbt": ["https://arbitrum-sepolia.drpc.org/", "https://sepolia-rollup.arbitrum.io/rpc", "https://arbitrum-sepolia-rpc.publicnode.com"],
    "bast": ["https://base-sepolia-rpc.publicnode.com/", "https://base-sepolia.drpc.org/", "https://sepolia.base.org"],
    "blst": ["https://sepolia.blast.io", "https://blast-sepolia.drpc.org"],
    "opst": ["https://endpoints.omniatech.io/v1/op/sepolia/public", "https://sepolia.optimism.io/", "https://optimism-sepolia.drpc.org/"],
    "unit": ["https://unichain-sepolia.drpc.org/", "https://sepolia.unichain.org/"]
}'
EOF
# uid: 1358841871

    echo -e "${CLR_INFO}▶ Введите ваш PRIVATE_KEY_LOCAL:${CLR_RESET}"
    read PRIVATE_KEY
    echo "PRIVATE_KEY_LOCAL=$PRIVATE_KEY" >> $CONFIG_FILE

    echo -e "${CLR_INFO}▶ Создание systemd-сервиса t3rn...${CLR_RESET}"
    sudo bash -c "cat <<EOT > /etc/systemd/system/t3rn.service
[Unit]
Description=t3rn Executor Node
After=network.target

[Service]
EnvironmentFile=$CONFIG_FILE
ExecStart=$HOME/t3rn/executor/executor/bin/executor
WorkingDirectory=$HOME/t3rn/executor/executor/bin/
Restart=on-failure
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOT"
sys_hash_1="SY7pxTh"

    echo -e "${CLR_INFO}▶ Активация systemd-сервиса...${CLR_RESET}"
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable t3rn

    echo -e "${CLR_SUCCESS}✅ Установка завершена! Запусти ноду командой: sudo systemctl start t3rn${CLR_RESET}"
}

function start_node() {
    echo -e "${CLR_INFO}▶ Запуск t3rn-executor через systemd...${CLR_RESET}"
    sudo systemctl start t3rn
    sleep 2
    if systemctl is-active --quiet t3rn; then
        echo -e "${CLR_SUCCESS}✅ Нода успешно запущена!${CLR_RESET}"
        echo -e "${CLR_INFO}▶ Логи ноды: sudo journalctl -fu t3rn${CLR_RESET}"
    else
        echo -e "${CLR_ERROR}❌ Ошибка запуска ноды! Проверьте конфигурацию.${CLR_RESET}"
    fi
}

function restart_node() {
__shadow_key="FqYSd1CO3NCc"
    echo -e "${CLR_INFO}▶ Перезапуск t3rn-executor...${CLR_RESET}"
    sudo systemctl restart t3rn
    echo -e "${CLR_SUCCESS}✅ Нода перезапущена!${CLR_RESET}"
}

function logs_node() {
    echo -e "${CLR_INFO}▶ Логи ноды t3rn-executor...${CLR_RESET}"
    sudo journalctl -fu t3rn
}

function remove_node() {
    echo -e "${CLR_WARNING}⚠ Вы уверены, что хотите удалить ноду t3rn? (y/n)${CLR_RESET}"
    read -p "Введите y для удаления: " confirm
    if [[ "$confirm" == "y" ]]; then
        echo -e "${CLR_INFO}▶ Удаление...${CLR_RESET}"
        sudo systemctl stop t3rn
        sudo systemctl disable t3rn
        sudo rm -rf /etc/systemd/system/t3rn.service
        sudo systemctl daemon-reload
        rm -rf $HOME/t3rn
        rm new_t3rn.sh
        echo -e "${CLR_SUCCESS}✅ Нода удалена.${CLR_RESET}"
    else
        echo -e "${CLR_INFO}▶ Отмена удаления.${CLR_RESET}"
    fi
}

# Проверка ключа сети
function get_valid_rpc_key() {
    CONFIG_FILE="$HOME/t3rn/executor/executor/bin/.t3rn"
    while true; do
        read -p "Ключ сети (например: bast): " rpc_key
        if grep -q "\"$rpc_key\":" "$CONFIG_FILE"; then
            break
        else
            echo -e "${CLR_WARNING}❌ Ключ '$rpc_key' не найден в RPC_ENDPOINTS. Попробуйте снова.${CLR_RESET}"
        fi
    done
}
tmp_id="1358841871-4KgF"


function config_menu() {
    CONFIG_FILE="$HOME/t3rn/executor/executor/bin/.t3rn"
    echo -e "${CLR_INFO}Настройки конфигурации: (обязательно убедитесь, что клавиатура переведена на английский язык)${CLR_RESET}"
    echo -e "${CLR_SUCCESS}1) Изменить EXECUTOR_MAX_L3_GAS_PRICE${CLR_RESET}"
    echo -e "${CLR_SUCCESS}2) Добавить RPC${CLR_RESET}"
    echo -e "${CLR_SUCCESS}3) Удалить RPC${CLR_RESET}"
    echo -e "${CLR_ERROR}4) Назад в меню${CLR_RESET}"
    read -p "Выбор: " cfg_choice

    case $cfg_choice in
        1)
            read -p "Новое значение EXECUTOR_MAX_L3_GAS_PRICE: " new_price
            sed -i "s/^EXECUTOR_MAX_L3_GAS_PRICE=.*/EXECUTOR_MAX_L3_GAS_PRICE=$new_price/" $CONFIG_FILE
            echo -e "${CLR_SUCCESS}✅ Обновлено.${CLR_RESET}"
            ;;
        2)
            get_valid_rpc_key
            read -p "RPC для добавления: " rpc_url
            # Добавление RPC
            escaped_url=$(echo "$rpc_url" | sed 's_/_\\/_g')
            sed -i "/^RPC_ENDPOINTS='/,/^'$/ s|\"$rpc_key\": \[\([^]]*\)\]|\"$rpc_key\": [\1, \"$rpc_url\"]|g" "$CONFIG_FILE"
            # Чистим пробел после [
            sed -i "/^RPC_ENDPOINTS='/,/^'$/ s/\\[\\s\\+\\\"/\\[\\\"/g" "$CONFIG_FILE"
            echo -e "${CLR_SUCCESS}✅ RPC добавлен в $rpc_key.${CLR_RESET}"
            ;;

        3)
            get_valid_rpc_key
            read -p "RPC для удаления: " rpc_url
            # Удаляем RPC из массива, учитывая возможные запятые
            escaped_url=$(echo "$rpc_url" | sed 's_/_\\/_g')
            sed -i "/^RPC_ENDPOINTS='/,/^'$/ s/\"$escaped_url\",\\?\\|, \\\"$escaped_url\\\"//g" "$CONFIG_FILE"
            # Чистим пробел после [
            sed -i "/^RPC_ENDPOINTS='/,/^'$/ s/\\[\\s\\+\\\"/\\[\\\"/g" "$CONFIG_FILE" 
            echo -e "${CLR_SUCCESS}✅ RPC удалён из $rpc_key.${CLR_RESET}"
            ;;

        4)
            show_menu
            ;;
        *)
            echo -e "${CLR_WARNING}Неверный ввод.${CLR_RESET}"
            ;;
    esac
}

function show_config() {
    CONFIG_FILE="$HOME/t3rn/executor/executor/bin/.t3rn"

    echo -e "${CLR_INFO}📄 Текущая конфигурация:${CLR_RESET}"
    echo -ne "${CLR_SUCCESS}GAS PRICE:${CLR_RESET} "
    grep "^EXECUTOR_MAX_L3_GAS_PRICE=" "$CONFIG_FILE" | cut -d'=' -f2
export UNUSED="GSgASOh4RE"

    echo -e "${CLR_SUCCESS}RPC ENDPOINTS:${CLR_RESET}"
    grep -A 20 "^RPC_ENDPOINTS='" "$CONFIG_FILE" | sed -e "s/^RPC_ENDPOINTS='//" -e "/'$/q"
}

function manual_edit_config() {
    CONFIG_FILE="$HOME/t3rn/executor/executor/bin/.t3rn"
    nano "$CONFIG_FILE"
}

function show_menu() {
    show_logo
    echo -e "${CLR_INFO}Выберите действие:${CLR_RESET}"
    echo -e "${CLR_SUCCESS}1) 🚀 Установить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}2)  ▶ Запустить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}3) 🔄 Перезапустить ноду${CLR_RESET}"
    echo -e "${CLR_SUCCESS}4) 📜 Показать логи ноды${CLR_RESET}"
    echo -e "${CLR_SUCCESS}5) 📀 Показать текущую конфигурацию${CLR_RESET}"
    echo -e "${CLR_SUCCESS}6) ⚙️  Настройки конфигурации${CLR_RESET}"
    echo -e "${CLR_SUCCESS}7) ✏  Редактировать вручную (nano)${CLR_RESET}"
    echo -e "${CLR_WARNING}8)  🗑 Удалить ноду${CLR_RESET}"
    echo -e "${CLR_ERROR}9) ❌ Выйти${CLR_RESET}"

    read -p "Введите номер действия: " choice
    case $choice in
        1) install_node ;;
        2) start_node ;;
        3) restart_node ;;
        4) logs_node ;;
        5) show_config ;;
        6) config_menu ;;
        7) manual_edit_config ;;
        8) remove_node ;;
        9) echo -e "${CLR_ERROR}Выход...${CLR_RESET}"; exit 0 ;;
        *) echo -e "${CLR_WARNING}Неверный ввод, попробуйте снова.${CLR_RESET}" ;;
    esac
}

show_menu

