#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

function show_logo() {
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${CYAN}     Добро пожаловать в скрипт установки ноды Cysic     ${NC}"
    echo -e "${GREEN}==========================================================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
    }

show_logo

echo -e "${YELLOW}Введите адрес вашего EVM-кошелька:${NC}"
read -r EVM_ADDRESS

if [[ -z "$EVM_ADDRESS" ]]; then
    echo -e "${RED}Ошибка: адрес EVM-кошелька не может быть пустым.${NC}"
    exit 1
fi

echo -e "${BLUE}Начинается установка ноды Cysic с адресом: ${EVM_ADDRESS}${NC}"
curl -L https://github.com/cysic-labs/phase2_libs/releases/download/v1.0.0/setup_linux.sh > ~/setup_linux.sh bash ~/setup_linux.sh "$EVM_ADDRESS"

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Установка завершена успешно!${NC}"
else
    echo -e "${RED}Установка завершилась с ошибкой.${NC}"
    exit 1
fi
