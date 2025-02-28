#!/bin/bash

# =============================
# 📌 УНИВЕРСАЛЬНЫЙ СКРИПТ УСТАНОВКИ ЗАВИСИМОСТЕЙ
# 💻 Подготовка сервера для установки нод (Ubuntu 20+)
# =============================

# Оформление текста: цвета и фоны
CLR_INFO='\033[1;97;44m'  # Белый текст на синем фоне
CLR_SUCCESS='\033[1;30;42m'  # Зеленый текст на черном фоне
CLR_ERROR='\033[1;31;40m'  # Красный текст на черном фоне
CLR_RESET='\033[0m'  # Сброс форматирования

# Функция для отображения логотипа сообщества
function show_logo() {
    echo -e "${CLR_INFO} Добро пожаловать в скрипт настройки сервера Profit Nodes ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Вызываем функцию для показа логотипа перед началом установки
show_logo


# 1️⃣ Обновление системы и установка базовых пакетов
echo -e "${CLR_INFO}🔄 Обновляем систему и устанавливаем основные утилиты...${CLR_RESET}"
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y software-properties-common curl wget git build-essential apt-transport-https ca-certificates gnupg lsb-release unzip

# 2️⃣ Установка Docker и Docker Compose
echo -e "${CLR_INFO}🐳 Устанавливаем Docker и Docker Compose...${CLR_RESET}"
sudo apt remove -y docker docker-engine docker.io containerd runc
sudo apt update -y
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 3️⃣ Установка Python 3, pip и virtualenv
echo -e "${CLR_INFO}🐍 Устанавливаем Python 3, pip и virtualenv...${CLR_RESET}"
sudo apt install -y python3 python3-pip python3-venv
pip3 install --upgrade pip setuptools wheel requests aiohttp faker

# 4️⃣ Установка Golang (Go)
echo -e "${CLR_INFO}🦀 Устанавливаем Go (Golang)...${CLR_RESET}"
sudo rm -rf /usr/local/go
wget https://go.dev/dl/go1.21.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.4.linux-amd64.tar.gz
rm go1.21.4.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> $HOME/.bashrc
source $HOME/.bashrc

# 5️⃣ Установка Node.js, npm, Yarn и PM2
echo -e "${CLR_INFO}🟢 Устанавливаем Node.js (LTS), npm и Yarn...${CLR_RESET}"
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
npm install -g pm2 yarn

# 6️⃣ Установка Rust и Cargo
echo -e "${CLR_INFO}🦀 Устанавливаем Rust и Cargo...${CLR_RESET}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# 7️⃣ Установка Git, jq, make, tmux, screen
echo -e "${CLR_INFO}🛠 Устанавливаем Git, jq, make, tmux и screen...${CLR_RESET}"
sudo apt install -y git jq make tmux screen

# 8️⃣ Установка сетевых утилит
echo -e "${CLR_INFO}🌐 Устанавливаем утилиты для работы с сетью...${CLR_RESET}"
sudo apt install -y net-tools dnsutils iputils-ping traceroute nmap ufw iptables

# 9️⃣ Установка инструментов мониторинга
echo -e "${CLR_INFO}📊 Устанавливаем утилиты для мониторинга ресурсов...${CLR_RESET}"
sudo apt install -y htop iotop iftop sysstat glances ncdu

# 🔟 Установка PostgreSQL (нужен для некоторых нод)
echo -e "${CLR_INFO}🐘 Устанавливаем PostgreSQL...${CLR_RESET}"
sudo apt install -y postgresql postgresql-contrib

# 1️⃣1️⃣ Установка баз данных: LevelDB, RocksDB, SQLite
echo -e "${CLR_INFO}💾 Устанавливаем библиотеки для работы с базами данных...${CLR_RESET}"
sudo apt install -y libleveldb-dev librocksdb-dev sqlite3 libsqlite3-dev

# 1️⃣2️⃣ Установка Bazel (для компиляции некоторых нод)
echo -e "${CLR_INFO}🛠 Устанавливаем Bazel...${CLR_RESET}"
sudo apt install -y apt-transport-https curl gnupg
curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > bazel-archive-keyring.gpg
sudo mv bazel-archive-keyring.gpg /usr/share/keyrings/
echo "deb [signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
sudo apt update -y && sudo apt install -y bazel

# 1️⃣3️⃣ Установка дополнительных библиотек и утилит
echo -e "${CLR_INFO}📦 Устанавливаем дополнительные библиотеки для нод...${CLR_RESET}"
sudo apt install -y clang libssl-dev llvm libudev-dev cmake protobuf-compiler

# 1️⃣4️⃣ Очистка кеша после установки
echo -e "${CLR_INFO}🧹 Очистка системы от ненужных файлов...${CLR_RESET}"
sudo apt autoremove -y && sudo apt clean

# ✅ Завершение установки
echo -e "${CLR_SUCCESS}🎉 Установка всех зависимостей завершена!${CLR_RESET}"
echo -e "${CLR_ERROR}🔄 Перезагрузите сервер перед установкой ноды: sudo reboot${CLR_RESET}"
