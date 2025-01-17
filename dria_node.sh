#!/bin/bash

# �������� ���� ��� ����������� ������
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # ����� �����

# ������� ��� ����������� ��������
function show_logo() {
    echo -e "${GREEN}===============================${NC}"
    echo -e "${CYAN} ����� ���������� � ������ ��������� ���� Dria ${NC}"
    echo -e "${GREEN}===============================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# ������� ��� ��������� ������������
function install_dependencies() {
    echo -e "${YELLOW}��������� ������� � ������������� ����������� ������...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git make jq build-essential gcc unzip wget lz4 aria2 curl
}

# ��������� ����
function install_node() {
    echo -e "${BLUE}�������� ��������� ���� Dria...${NC}"
    install_dependencies

    ARCH=$(uname -m)
    if [[ "$ARCH" == "aarch64" ]]; then
        DOWNLOAD_URL="https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-arm64.zip"
    elif [[ "$ARCH" == "x86_64" ]]; then
        DOWNLOAD_URL="https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-amd64.zip"
    else
        echo -e "${RED}����������� ����������� �������: $ARCH. ��������� ����������.${NC}"
        exit 1
    fi

    curl -L -o dkn-compute-node.zip $DOWNLOAD_URL
    unzip dkn-compute-node.zip -d dkn-compute-node
    cd dkn-compute-node || { echo -e "${RED}�� ������� ����� � ���������� ���������. ����������.${NC}"; exit 1; }
    ./dkn-compute-launcher
}

# �������� � ������ �������
function create_and_start_service() {
    echo -e "${BLUE}����������� ��������� ������ ��� ���� Dria...${NC}"
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo "~$USERNAME")

    sudo bash -c "cat <<EOT > /etc/systemd/system/dria.service
[Unit]
Description=Dria Compute Node Service
After=network.target

[Service]
User=$USERNAME
EnvironmentFile=$HOME_DIR/dkn-compute-node/.env
ExecStart=$HOME_DIR/dkn-compute-node/dkn-compute-launcher
WorkingDirectory=$HOME_DIR/dkn-compute-node/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

    sudo systemctl daemon-reload
    sudo systemctl enable dria
    sudo systemctl start dria
    echo -e "${GREEN}������ Dria �������!${NC}"
}

# ���������� ����
function update_node() {
    echo -e "${BLUE}���������� ���� �� ��������� ������...${NC}"
    sudo systemctl stop dria
    rm -rf $HOME/dkn-compute-node
    install_node
    create_and_start_service
    echo -e "${GREEN}���� ���������!${NC}"
}

# ��������� �����
function change_port() {
    echo -e "${YELLOW}������� ����� ���� ��� ���� Dria:${NC}"
    read -r NEW_PORT
    sed -i "s|DKN_P2P_LISTEN_ADDR=/ip4/0.0.0.0/tcp/[0-9]*|DKN_P2P_LISTEN_ADDR=/ip4/0.0.0.0/tcp/$NEW_PORT|" "$HOME/dkn-compute-node/.env"
    sudo systemctl restart dria
    echo -e "${GREEN}���� ������� ������� �� $NEW_PORT.${NC}"
}

# �������� �����
function check_logs() {
    echo -e "${BLUE}�������� ����� ���� Dria...${NC}"
    sudo journalctl -u dria -f --no-hostname -o cat
}

# �������� ����
function remove_node() {
    echo -e "${BLUE}�������� ���� Dria...${NC}"
    sudo systemctl stop dria
    sudo systemctl disable dria
    sudo rm /etc/systemd/system/dria.service
    rm -rf $HOME/dkn-compute-node
    sudo systemctl daemon-reload
    echo -e "${GREEN}���� ������� �������.${NC}"
}

# ���� ������ ��������
function show_menu() {
    show_logo
    echo -e "${CYAN}1) ?? ���������� ����${NC}"
    echo -e "${CYAN}2) ?? ��������� ����${NC}"
    echo -e "${CYAN}3) ??  �������� ����${NC}"
    echo -e "${CYAN}4) ??  �������� ����${NC}"
    echo -e "${CYAN}5) ?? �������� �����${NC}"
    echo -e "${CYAN}6) ???  ������� ����${NC}"
    echo -e "${CYAN}7) ? �����${NC}"
    echo -e "${YELLOW}������� �����:${NC}"
    read -r choice

    case $choice in
        1) install_node ;;
        2) create_and_start_service ;;
        3) update_node ;;
        4) change_port ;;
        5) check_logs ;;
        6) remove_node ;;
        7) echo -e "${GREEN}�����...${NC}" ;;
        *) echo -e "${RED}�������� �����. ���������� �����.${NC}" ;;
    esac
}

# ������ ����
show_menu
