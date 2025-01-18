#!/bin/bash

# Отображение цветов 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'  

# Отображение лого 
    echo -e "${GREEN}===============================${NC}"
    echo -e "${CYAN} Добро пожаловать в скрипт установки ноды Zero Gravity ${NC}"
    echo -e "${GREEN}===============================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash

# Установка ноды OG
echo -e "${CYAN}Устанавливаем ноду OG...${NC}"
if source <(curl -s https://raw.githubusercontent.com/zstake-xyz/test/refs/heads/main/0g_storage_installer.sh); then
    echo -e "${GREEN}Нода успешно установлена!${NC}"
else
    echo -e "${RED}Ошибка при установки ноды .${NC}"
    exit 1
fi
