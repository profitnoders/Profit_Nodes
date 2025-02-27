#!/bin/bash

# Оформление текста: цвета и фоны
CLR_INFO='\033[1;97;44m'  # Белый текст на синем фоне
CLR_SUCCESS='\033[1;30;42m'  # Зеленый текст на черном фоне
CLR_WARNING='\033[1;37;41m'  # Белый текст на красном фоне
CLR_ERROR='\033[1;31;40m'  # Красный текст на черном фоне
CLR_RESET='\033[0m'  # Сброс форматирования

# Отображение лого 
    echo -e "${CLR_SUCCESS}===============================${CLR_RESET}"
    echo -e "${CLR_SUCCESS} Добро пожаловать в скрипт установки ноды Zero Gravity ${CLR_RESET}"
    echo -e "${CLR_SUCCESS}===============================${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash

# Установка ноды OG
echo -e "${CLR_INFO}Устанавливаем ноду OG...${CLR_RESET}"
if source <(curl -s https://raw.githubusercontent.com/zstake-xyz/test/refs/heads/main/0g_storage_installer.sh); then
    echo -e "${CLR_SUCCESS}Нода успешно установлена!${CLR_RESET}"
else
    echo -e "${CLR_ERROR}Ошибка при установки ноды .${CLR_RESET}"
    exit 1
fi
