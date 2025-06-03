#!/bin/bash

# Оформление текста: цвета и фоны
CLR_INFO='\033[1;97;44m'  # Белый текст на синем фоне
CLR_SUCCESS='\033[1;30;42m'  # Зеленый текст на черном фоне
CLR_WARNING='\033[1;37;41m'  # Белый текст на красном фоне
CLR_ERROR='\033[1;31;40m'  # Красный текст на черном фоне
CLR_RESET='\033[0m'  # Сброс форматирования
CLR_GREEN='\033[0;32m' # Зеленый текст

# Функция отображения логотипа
function show_logo() {
    echo -e "${CLR_SUCCESS} Добро пожаловать в скрипт установки ноды Dria ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Функция установки зависимостей
function install_dependencies() {
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git make jq build-essential gcc unzip wget curl
    # Проверка Docker
    echo -e "${CLR_INFO}▶ Проверка наличия Docker...${CLR_RESET}"
    if ! command -v docker &> /dev/null; then
        echo "Docker не найден. Устанавливаю..."
        sudo apt update
        sudo apt install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin 
        sudo systemctl enable --now docker
    fi

    echo -e "${CLR_INFO}▶ Проверка наличия Docker Compose...${CLR_RESET}"

    if command -v docker compose &> /dev/null; then
    echo -e "${CLR_SUCCESS}✔ Найден Docker Compose v2 (docker compose).${CLR_RESET}"
    DOCKER_COMPOSE="docker compose"
    elif command -v docker-compose &> /dev/null; then
    echo -e "${CLR_SUCCESS}✔ Найден Docker Compose v1 (docker-compose).${CLR_RESET}"
    DOCKER_COMPOSE="docker-compose"
    else
    echo -e "${CLR_WARNING}⚠ Docker Compose не найден. Устанавливаю v1...${CLR_RESET}"
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    DOCKER_COMPOSE="docker-compose"
    fi

    # Проверим ещё раз после установки
    if ! command -v $DOCKER_COMPOSE &> /dev/null; then
    echo -e "${CLR_ERROR}❌ Ошибка установки Docker Compose!${CLR_RESET}"
    exit 1
    fi


    # Добавление пользователя в группу docker
    sudo usermod -aG docker $USER
    sleep 1
}

# Установка ноды
function install_node() {
    echo -e "${CLR_INFO}Начинаем установку ноды Dria...${CLR_RESET}"
    install_dependencies

    # Установка новой версии лаунчера
    curl -fsSL https://dria.co/launcher | bash

    echo -e "${CLR_SUCCESS}Бинарник установлен!${CLR_RESET}"
    echo "Создаем директорию dria-mult..."
    mkdir -p dria-mult

    # Запрашиваем количество контейнеров
    while true; do
    read -p "Сколько контейнеров (от 2 до 10) вы хотите создать? " NUM_CONTAINERS
    if [[ $NUM_CONTAINERS -ge 2 && $NUM_CONTAINERS -le 10 ]]; then
        break
    else
        echo "Пожалуйста, введите число от 2 до 10."
    fi
    done

    # Запрашиваем, будет ли использоваться прокси
    read -p "Будете использовать прокси? (y/n) " USE_PROXY

    if [[ "$USE_PROXY" == "y" || "$USE_PROXY" == "Y" ]]; then
    read -p "Введите адрес прокси (например: http://user:pass@host:port): " PROXY
    fi

    # Скачиваем Dockerfile
    echo "Скачиваем Dockerfile в директорию dria-mult..."
    cd dria-mult
    curl -fsSL https://raw.githubusercontent.com/profitnoders/Profit_Nodes/main/dria/Dockerfile -o Dockerfile

    # Создаем директорию nodes и поддиректории для каждого контейнера
    mkdir -p nodes
    for ((i=1; i<=NUM_CONTAINERS; i++)); do
    mkdir -p nodes/node$i
    done

    # Копируем директорию .dria в каждую папку
    echo "Копируем директорию .dria в каждую папку контейнера и создаём env файлы..."
    for ((i=1; i<=NUM_CONTAINERS; i++)); do
    cp -r ~/.dria nodes/node$i/
    
    done

    # Запрашиваем API-ключ ChatGPT
    read -p "Введите API-ключ ChatGPT: " CHATGPT_API_KEY

    # Генерируем docker-compose.yml
    echo "Создаем docker-compose.yml..."
    cat > docker-compose.yml <<EOF
version: '3.8'
services:
EOF
    echo "Сейчас вам понадобятся $NUM_CONTAINERS приватных ключей, чтобы запустить ноды."
    for (( i=1; i<=NUM_CONTAINERS; i++ ))
    do
    # Запрашиваем приватный ключ для каждого контейнера
    read -p "Введите приватный ключ для node$i: " DKN_WALLET_SECRET_KEY

    # Создаем директории, если не существуют
    NODE_DIR="./nodes/node$i/.dria"
    mkdir -p "$NODE_DIR/dkn-compute-launcher"

    # Скачиваем .env-файл
    ENV_URL="https://raw.githubusercontent.com/profitnoders/Profit_Nodes/main/dria/.env"
    ENV_FILE="$NODE_DIR/dkn-compute-launcher/.env"
    curl -s -o "$ENV_FILE" "$ENV_URL"

    # Заменяем порт в файле .env
    PORT="400$i"
    sed -i "s|DKN_P2P_LISTEN_ADDR=.*|DKN_P2P_LISTEN_ADDR=/ip4/0.0.0.0/tcp/$PORT|" "$ENV_FILE"

    # Добавляем API-ключ и приватный ключ в .env
    # Заменяем (или добавляем) строку OPENAI_API_KEY
    if grep -q '^OPENAI_API_KEY=' "$ENV_FILE"; then
    sed -i "s|^OPENAI_API_KEY=.*|OPENAI_API_KEY=$CHATGPT_API_KEY|" "$ENV_FILE"
    else
    echo "OPENAI_API_KEY=$CHATGPT_API_KEY" >> "$ENV_FILE"
    fi

    # Заменяем (или добавляем) строку DKN_WALLET_SECRET_KEY
    if grep -q '^DKN_WALLET_SECRET_KEY=' "$ENV_FILE"; then
    sed -i "s|^DKN_WALLET_SECRET_KEY=.*|DKN_WALLET_SECRET_KEY=$DKN_WALLET_SECRET_KEY|" "$ENV_FILE"
    else
    echo "DKN_WALLET_SECRET_KEY=$DKN_WALLET_SECRET_KEY" >> "$ENV_FILE"
    fi

    # Добавляем сервис в docker-compose.yml
    cat >> docker-compose.yml <<EOF
    dria-node-$i:
        build: .
        container_name: dria_node_$i
        volumes:
        - ./nodes/node$i/.dria:/root/.dria
        ports:
        - "$PORT:$PORT"
EOF

    if [[ "$USE_PROXY" == "y" || "$USE_PROXY" == "Y" ]]; then
        cat >> docker-compose.yml <<EOF
        environment:
        - http_proxy=$PROXY
        - https_proxy=$PROXY
EOF
    fi

    cat >> docker-compose.yml <<EOF
        command: bash -c "./.dria/bin/dkn-compute-launcher start"
EOF
    done

    echo "Файл docker-compose.yml успешно создан с $NUM_CONTAINERS контейнерами."
    echo "Все директории .dria подготовлены, приватные ключи и API-ключи вставлены."
}

function sum_points() {
    cd ~/dria-mult || exit 1
    total=0

    # Получаем список контейнеров из docker-compose.yml
    containers=$(docker-compose ps --services)

    for container in $containers; do
        # Ищем последнюю строку с $DRIA Points для каждого контейнера
        last_line=$(docker-compose logs "$container" 2>/dev/null | grep '\$DRIA Points:' | tail -n 1)

        if [[ -n "$last_line" ]]; then
            # Извлекаем число после $DRIA Points:
            points=$(echo "$last_line" | sed -n 's/.*\$DRIA Points: \([0-9]\+\).*/\1/p')
            echo "Контейнер $container: $points points"

            # Суммируем
            total=$((total + points))
        else
            echo "Контейнер $container: $CLR_WARNING нет строки с \$DRIA Points$CLR_RESET"
        fi
    done

    echo -e "${CLR_SUCCESS}Сумма всех $DRIA Points: $total${CLR_RESET}"
}


function start_node() {
    cd ~/dria-mult
    docker-compose up -d
}

function restart_node() {
    cd ~/dria-mult
    docker-compose down && docker-compose up -d
}

function show_logs() {
    cd ~/dria-mult
    docker-compose logs --tail 200 -f
}

function remove_node() {
    cd ~/dria-mult
    docker-compose down
    cd ~
    rm -rf ~/dria-mult
}

# Меню выбора действий
function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1) 🚀 Массовая установка нод${CLR_RESET}"
    echo -e "${CLR_GREEN}2) ✅ Запустить docker-compose${CLR_RESET}"
    echo -e "${CLR_GREEN}3) 🔄 Перезапустить docker-compose${CLR_RESET}"
    echo -e "${CLR_GREEN}4) 📋 Посмотреть логи${CLR_RESET}"
    echo -e "${CLR_GREEN}5) 💰 Посчитать сумму всех DRIA Points${CLR_RESET}"
    echo -e "${CLR_GREEN}6) 🗑️  Удалить ноду${CLR_RESET}"
    echo -e "${CLR_GREEN}7) ❌ Выйти${CLR_RESET}"
    echo -e "${CLR_INFO}Введите номер:${CLR_RESET}"
    read -r choice

    case $choice in
        1) install_node ;;
        2) start_node ;;
        3) restart_node ;;
        4) show_logs ;;
        5) sum_points ;;
        6) remove_node ;;
        7) echo -e "${CLR_ERROR}Выход...${CLR_RESET}" ;;
        *) echo -e "${CLR_WARNING}Неверный выбор. Попробуйте снова.${CLR_RESET}" ;;
    esac
}

# Запуск меню
show_menu
