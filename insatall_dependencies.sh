#!/bin/bash

# =============================
# 📌 УНИВЕРСАЛЬНЫЙ СКРИПТ УСТАНОВКИ ЗАВИСИМОСТЕЙ
# 💻 Подготовка сервера для установки нод (Ubuntu 20+)
# =============================

# Цветовые коды для оформления текста
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RED='\033[1;31m'
NC='\033[0m' # Сброс цвета

# Функция для отображения логотипа сообщества
function show_logo() {
    echo -e "${GREEN}============================================${NC}"
    echo -e "${CYAN} Добро пожаловать в скрипт настройки сервера Profit Nodes ${NC}"
    echo -e "${GREEN}============================================${NC}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# Вызываем функцию для показа логотипа перед началом установки
show_logo

echo -e "${CYAN}🚀 Начинаем установку всех необходимых зависимостей...${NC}"

# 1️⃣ Обновление системы и установка базовых пакетов
echo -e "${YELLOW}🔄 Обновляем систему и устанавливаем основные утилиты...${NC}"
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y software-properties-common curl wget git build-essential apt-transport-https ca-certificates gnupg lsb-release unzip

# 2️⃣ Установка Docker и Docker Compose
echo -e "${YELLOW}🐳 Устанавливаем Docker и Docker Compose...${NC}"
sudo apt remove -y docker docker-engine docker.io containerd runc
sudo apt update -y
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 3️⃣ Установка Python 3, pip и virtualenv
echo -e "${YELLOW}🐍 Устанавливаем Python 3, pip и virtualenv...${NC}"
sudo apt install -y python3 python3-pip python3-venv
pip3 install --upgrade pip setuptools wheel requests aiohttp faker

# 4️⃣ Установка Golang (Go)
echo -e "${YELLOW}🦀 Устанавливаем Go (Golang)...${NC}"
sudo rm -rf /usr/local/go
wget https://go.dev/dl/go1.21.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.4.linux-amd64.tar.gz
rm go1.21.4.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> $HOME/.bashrc
source $HOME/.bashrc

# 5️⃣ Установка Node.js, npm, Yarn и PM2
echo -e "${YELLOW}🟢 Устанавливаем Node.js (LTS), npm и Yarn...${NC}"
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
npm install -g pm2 yarn

# 6️⃣ Установка Rust и Cargo
echo -e "${YELLOW}🦀 Устанавливаем Rust и Cargo...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# 7️⃣ Установка Git, jq, make, tmux, screen
echo -e "${YELLOW}🛠 Устанавливаем Git, jq, make, tmux и screen...${NC}"
sudo apt install -y git jq make tmux screen

# 8️⃣ Установка сетевых утилит
echo -e "${YELLOW}🌐 Устанавливаем утилиты для работы с сетью...${NC}"
sudo apt install -y net-tools dnsutils iputils-ping traceroute nmap ufw iptables

# 9️⃣ Установка инструментов мониторинга
echo -e "${YELLOW}📊 Устанавливаем утилиты для мониторинга ресурсов...${NC}"
sudo apt install -y htop iotop iftop sysstat glances ncdu

# 🔟 Установка PostgreSQL (нужен для некоторых нод)
echo -e "${YELLOW}🐘 Устанавливаем PostgreSQL...${NC}"
sudo apt install -y postgresql postgresql-contrib

# 1️⃣1️⃣ Установка баз данных: LevelDB, RocksDB, SQLite
echo -e "${YELLOW}💾 Устанавливаем библиотеки для работы с базами данных...${NC}"
sudo apt install -y libleveldb-dev librocksdb-dev sqlite3 libsqlite3-dev

# 1️⃣2️⃣ Установка Bazel (для компиляции некоторых нод)
echo -e "${YELLOW}🛠 Устанавливаем Bazel...${NC}"
sudo apt install -y apt-transport-https curl gnupg
curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > bazel-archive-keyring.gpg
sudo mv bazel-archive-keyring.gpg /usr/share/keyrings/
echo "deb [signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
sudo apt update -y && sudo apt install -y bazel

# 1️⃣3️⃣ Установка дополнительных библиотек и утилит
echo -e "${YELLOW}📦 Устанавливаем дополнительные библиотеки для нод...${NC}"
sudo apt install -y clang libssl-dev llvm libudev-dev cmake protobuf-compiler

# 1️⃣4️⃣ Очистка кеша после установки
echo -e "${YELLOW}🧹 Очистка системы от ненужных файлов...${NC}"
sudo apt autoremove -y && sudo apt clean

# ✅ Завершение установки
echo -e "${GREEN}🎉 Установка всех зависимостей завершена!${NC}"
echo -e "${CYAN}🔄 Перезагрузите сервер перед установкой ноды: sudo reboot${NC}"
