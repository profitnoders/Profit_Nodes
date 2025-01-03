#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Отображаем логотип
curl -s https://raw.githubusercontent.com/Danzelitos/node_testing/refs/heads/main/logo.sh | bash
# Меню
echo -e "${BLUE}Выберите действие:${NC}"
echo -e "${YELLOW}1) Установка ноды${NC}"
echo -e "${YELLOW}2) Проверка статуса ноды${NC}"
echo -e "${YELLOW}3) Удаление ноды${NC}"

echo -e "${BLUE}Введите номер:${NC} "
read choice