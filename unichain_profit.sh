#!/bin/bash

# ����� ������
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # ����� �����

# �������
function show_logo() {
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${CYAN}     ����� ���������� � ������ ��������� ���� Unichain     ${NC}"
    echo -e "${GREEN}==========================================================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# ��������� ����������� �������
function install_dependencies() {
    echo -e "${YELLOW}��������� ������� � ������������� �����������...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl git docker.io
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
}

# ��������� ����
function install_node() {
    echo -e "${BLUE}�������� ��������� ���� Unichain...${NC}"
    install_dependencies

    # ��������� �����������
    if [ ! -d "$HOME/unichain-node" ]; then
        echo -e "${BLUE}��������� ����������� Uniswap Unichain Node...${NC}"
        git clone https://github.com/Uniswap/unichain-node $HOME/unichain-node
    else
        echo -e "${BLUE}����� unichain-node ��� ����������. ���������� ������������.${NC}"
    fi

    cd $HOME/unichain-node || { echo -e "${RED}������: �� ������� ����� � ���������� unichain-node.${NC}"; exit 1; }

    # ��������� .env.sepolia
    if [ -f ".env.sepolia" ]; then
        echo -e "${BLUE}��������� ���� .env.sepolia...${NC}"
        sed -i 's|^OP_NODE_L1_ETH_RPC=.*|OP_NODE_L1_ETH_RPC=https://ethereum-sepolia-rpc.publicnode.com|' .env.sepolia
        sed -i 's|^OP_NODE_L1_BEACON=.*|OP_NODE_L1_BEACON=https://ethereum-sepolia-beacon-api.publicnode.com|' .env.sepolia
    else
        echo -e "${RED}������: ���� .env.sepolia �� ������.${NC}"
        exit 1
    fi

    # ��������� ����������
    echo -e "${BLUE}��������� ���������� � ������� docker-compose...${NC}"
    docker-compose up -d

    echo -e "${GREEN}��������� ���������! ���� ��������.${NC}"
}

# ���������� ����
function update_node() {
    echo -e "${BLUE}��������� ���� Unichain...${NC}"
    cd $HOME/unichain-node || { echo -e "${RED}������: �� ������� ����� � ���������� unichain-node.${NC}"; exit 1; }
    docker-compose pull
    docker-compose up -d
    echo -e "${GREEN}���� ������� ���������.${NC}"
}

# �������� �����
function check_logs() {
    echo -e "${BLUE}�������� ����� Unichain...${NC}"
    cd $HOME/unichain-node || { echo -e "${RED}������: �� ������� ����� � ���������� unichain-node.${NC}"; exit 1; }
    docker-compose logs -f
}

# �������� �������
function check_status() {
    echo -e "${BLUE}�������� ������� ���� Unichain...${NC}"
    curl -d '{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
    -H "Content-Type: application/json" http://localhost:8545
}

# �������� ����
function remove_node() {
    echo -e "${BLUE}������� ���� Unichain...${NC}"
    cd $HOME/unichain-node || { echo -e "${RED}������: �� ������� ����� � ���������� unichain-node.${NC}"; exit 1; }
    docker-compose down -v
    cd $HOME
    rm -rf $HOME/unichain-node
    echo -e "${GREEN}���� ������� �������.${NC}"
}

# ����
function show_menu() {
    show_logo
    echo -e "${CYAN}1) ?? ���������� ����${NC}"
    echo -e "${CYAN}2) ?? �������� ����${NC}"
    echo -e "${CYAN}3) ?? �������� �����${NC}"
    echo -e "${CYAN}4) ?? �������� �������${NC}"
    echo -e "${CYAN}5) ??? ������� ����${NC}"
    echo -e "${CYAN}6) ? �����${NC}"

    echo -e "${YELLOW}�������� ��������:${NC}"
    read -r choice
    case $choice in
        1) install_node ;;
        2) update_node ;;
        3) check_logs ;;
        4) check_status ;;
        5) remove_node ;;
        6) echo -e "${GREEN}�����...${NC}" ;;
        *) echo -e "${RED}�������� �����!${NC}" ;;
    esac
}

# ������ ����
show_menu
