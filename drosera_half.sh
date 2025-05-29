#!/bin/bash

CLR_INFO='\033[1;97;44m'
CLR_SUCCESS='\033[1;97;42m'
CLR_WARNING='\033[1;30;103m'
CLR_ERROR='\033[1;97;41m'
CLR_GREEN='\033[0;32m'
CLR_RESET='\033[0m'
#123
function show_logo() {
    echo -e "${CLR_GREEN}          Установочный скрипт для ноды Drosera             ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}


function create_operator() {
    export PATH="$HOME/.foundry-drosera/bin:$PATH"
    cd $HOME/my-drosera-trap
    read -p "Введите EVM адрес: " WALLET
    read -p "Введите ваш кастомный Ethereum RPC: " CUSTOM_RPC
    sed -i "s|^ethereum_rpc = \".*\"|ethereum_rpc = \"$CUSTOM_RPC\"|" "$HOME/my-drosera-trap/drosera.toml"
    sed -i 's/^[[:space:]]*private = true/private_trap = true/' "$HOME/my-drosera-trap/drosera.toml"
    sed -i "/^whitelist/c\whitelist = [\"$WALLET\"]" "$HOME/my-drosera-trap/drosera.toml"
    sed -i 's|^drosera_rpc = "https://1rpc.io/holesky"|drosera_rpc = "https://relay.testnet.drosera.io/"|' "$HOME/my-drosera-trap/drosera.toml"
    read -p "Введите приватный ключ: " PRIV_KEY
    export PATH="$HOME/.drosera/bin:$PATH"
    cd $HOME/my-drosera-trap && DROSERA_PRIVATE_KEY="$PRIV_KEY" drosera apply
}

function install_cli() {
    cd ~
    curl -LO https://github.com/drosera-network/releases/releases/download/v1.17.2/drosera-operator-v1.17.2-x86_64-unknown-linux-gnu.tar.gz
    tar -xvf drosera-operator-v1.17.2-x86_64-unknown-linux-gnu.tar.gz
    sudo cp drosera-operator /usr/bin
    docker pull ghcr.io/drosera-network/drosera-operator:latest
    read -p "Введите приватный ключ: " PRIV_KEY
    export PATH="$HOME/.drosera/bin:$PATH"
    read -p "Введите вашу  RPC Holesky : " YOUR_RPC
    drosera-operator register --eth-rpc-url "$YOUR_RPC" --eth-private-key "$PRIV_KEY"
#    read -p "Введите IP сервера: " IP_ADDRESS
    IP_ADDRESS=$(curl -s api.ipify.org)
    sudo bash -c "cat <<EOF > /etc/systemd/system/drosera.service
[Unit]
Description=Drosera Node
After=network-online.target

[Service]
User=$USER
Restart=always
RestartSec=15
LimitNOFILE=65535
ExecStart=/usr/bin/drosera-operator node --db-file-path \$HOME/.drosera.db --network-p2p-port 31313 --server-port 31314 \\
    --eth-rpc-url \"$YOUR_RPC\" \\
    --eth-backup-rpc-url https://holesky.drpc.org/ \\
    --drosera-address 0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8 \\
    --eth-private-key \"$PRIV_KEY\" \\
    --listen-address 0.0.0.0 \\
    --network-external-p2p-address $IP_ADDRESS \\
    --disable-dnr-confirmation true

[Install]
WantedBy=multi-user.target
EOF"

    echo -e "${CLR_INFO}▶ Настраиваем безопасный фаервол (UFW)...${CLR_RESET}"
    sudo ufw allow 22/tcp
    sudo ufw allow 31313/tcp
    sudo ufw allow 31314/tcp
    sudo ufw allow 30304/tcp

    # Проверим активен ли уже UFW, если нет — включим
    if sudo ufw status | grep -q inactive; then
        echo -e "${CLR_INFO}▶ Включаем UFW...${CLR_RESET}"
        sudo ufw --force enable
    else
        echo -e "${CLR_SUCCESS}✅ UFW уже включен. Пропускаем.${CLR_RESET}"
    fi

    sudo systemctl daemon-reload
    sudo systemctl enable drosera
    sudo systemctl start drosera
}
function check_logs() {
    journalctl -u drosera.service -f
}

function restart_node() {
    sudo systemctl restart drosera
    echo -e "${CLR_INFO}✅ Нода перезапущена.${CLR_RESET}"
}

function delete_node() {
    read -p "⚠ Удалить ноду Drosera? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        sudo systemctl stop drosera
        sudo systemctl disable drosera
        sudo rm /etc/systemd/system/drosera.service
        sudo systemctl daemon-reload
        rm -rf $HOME/.drosera $HOME/.drosera.db $HOME/.foundry-drosera $HOME/.bun $HOME/my-drosera-trap $HOME/drosera-operator*
        echo -e "${CLR_SUCCESS}✅ Нода полностью удалена.${CLR_RESET}"
    fi
}

function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1)🖥️ Создание оператора${CLR_RESET}"
    echo -e "${CLR_GREEN}2)🚀 Запуск CLI и systemd${CLR_RESET}"
    echo -e "${CLR_GREEN}3)🔄 Перезапуск ноды${CLR_RESET}"
    echo -e "${CLR_GREEN}4)📜 Просмотр логов${CLR_RESET}"
    echo -e "${CLR_GREEN}5)🗑️ Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}6)❌ Выйти${CLR_RESET}"
    read -p "Выберите пункт: " choice
    case $choice in
        1) create_operator;;
        2) install_cli;;
        3) restart_node;;
        4) check_logs;;
        5) delete_node;;
        6) echo -e "${CLR_SUCCESS}Выход...${CLR_RESET}" && exit 0 ;;
        *) echo -e "${CLR_ERROR}Неверный выбор!${CLR_RESET}";;
    esac
}

show_menu