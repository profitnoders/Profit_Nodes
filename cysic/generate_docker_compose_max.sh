#!/bin/bash

# Оформление текста: цвета и фоны
CLR_INFO='\033[1;97;44m'      # Белый текст на синем фоне
CLR_SUCCESS='\033[1;30;42m'   # Зеленый текст на черном фоне
CLR_WARNING='\033[1;37;41m'   # Белый текст на красном фоне
CLR_ERROR='\033[1;31;40m'     # Красный текст на черном фоне
CLR_RESET='\033[0m'           # Сброс форматирования
CLR_GREEN='\033[0;32m'        # Зеленый текст

# Ввод количества верифаеров
echo -ne "${CLR_GREEN}Сколько верифаеров вы хотите установить: ${CLR_RESET}"
read CNT

# Ввод REWARD_ADDRESS
echo -ne "${CLR_GREEN}Введите REWARD_ADDRESS: ${CLR_RESET}"
read REWARD

# Генерация docker-compose.yml
cat > docker-compose.yml <<EOC
services:
EOC

for i in $(seq 1 $CNT); do
  cat >> docker-compose.yml <<EOC
  verifier_$i:
    build: .
    image: cysic_verifier_image:latest
    environment:
      - REWARD_ADDRESS=$REWARD
    volumes:
      - ./data/verifier_$i:/root
    container_name: verifier_$i
    restart: unless-stopped

EOC
done

echo -e "${CLR_SUCCESS}✅ docker-compose.yml готов для $CNT верифаеров.${CLR_RESET}"
