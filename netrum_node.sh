#!/bin/bash

# ---------- Цвета ----------
CLR_SUCCESS='\033[1;32m'
CLR_INFO='\033[1;34m'
CLR_WARNING='\033[1;33m'
CLR_ERROR='\033[1;31m'
CLR_RESET='\033[0m'

# ---------- Пути/переменные ----------
APP_DIR="$HOME/netrum-lite-node"

# ---------- Логотип ----------
show_logo() {
  echo -e "${CLR_INFO}     Добро пожаловать в установщик Netrum Lite Node     ${CLR_RESET}"
  curl -fsSL https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}

# ---------- Установка зависимостей ----------
function install_dependencies() {
    echo -e "${CLR_WARNING}🔄 Установка зависимостей...${CLR_RESET}"
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install -y curl git jq build-essential python3 make g++ wget

    # Удаляем старый Node.js и npm
    sudo apt purge -y nodejs npm || true
    sudo apt autoremove -y
    sudo rm -f /usr/bin/node /usr/local/bin/node /usr/bin/npm /usr/local/bin/npm

    # Устанавливаем Node.js 20 через NodeSource
    echo -e "${CLR_INFO}🚀 Установка Node.js 20 и npm...${CLR_RESET}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs

    echo -e "${CLR_SUCCESS}✅ Node.js версия: $(node -v)${CLR_RESET}"
    echo -e "${CLR_SUCCESS}✅ npm версия: $(npm -v)${CLR_RESET}"
}

# ---------- Установка и запуск ноды ----------
install_node() {
  install_dependencies

  echo -e "${CLR_INFO}📥 Клонирование репозитория...${CLR_RESET}"
  if [ -d "$APP_DIR" ]; then
    echo -e "${CLR_WARNING}Каталог уже существует: $APP_DIR — обновляю.${CLR_RESET}"
    cd "$APP_DIR" && git pull
  else
    git clone https://github.com/NetrumLabs/netrum-lite-node.git "$APP_DIR"
    cd "$APP_DIR" || { echo -e "${CLR_ERROR}Не удалось войти в $APP_DIR${CLR_RESET}"; return; }
  fi

  echo -e "${CLR_INFO}📦 Установка npm-зависимостей...${CLR_RESET}"
  npm install

  echo -e "${CLR_INFO}🔗 Глобальная ссылка CLI (npm link)...${CLR_RESET}"
  npm link

  echo -e "${CLR_SUCCESS}✅ Установка завершена. Запуск интерфейса: netrum${CLR_RESET}"
  echo -e "${CLR_INFO}Совет: далее выберите «3) Управление нодой» для действий (кошелёк, регистрация, майнинг и др.).${CLR_RESET}"
}

# =========================================================
#                ПОДМЕНЮ: УПРАВЛЕНИЕ НОДОЙ
# =========================================================
nodes_manage() {
  while true; do
    echo
    echo -e "${CLR_INFO}=== Управление нодой Netrum ===${CLR_RESET}"
    echo -e "${CLR_INFO}1)  Проверка системы (netrum-system)${CLR_RESET}"
    echo -e "${CLR_INFO}2)  Создать НОВЫЙ кошелёк (netrum-new-wallet)${CLR_RESET}"
    echo -e "${CLR_INFO}3)  Импорт кошелька по приватному ключу (netrum-import-wallet)${CLR_RESET}"
    echo -e "${CLR_INFO}4)  Показать кошелёк/баланс (netrum-wallet)${CLR_RESET}"
    echo -e "${CLR_INFO}5)  Экспорт приватного ключа (netrum-wallet-key)${CLR_RESET}"
    echo -e "${CLR_INFO}6)  Удалить кошелёк с сервера (netrum-wallet-remove)${CLR_RESET}"
    echo -e "${CLR_INFO}7)  Проверить Base-name (netrum-check-basename)${CLR_RESET}"
    echo -e "${CLR_INFO}8)  Показать Node ID (netrum-node-id)${CLR_RESET}"
    echo -e "${CLR_INFO}9)  Очистить Node ID (netrum-node-id-remove)${CLR_RESET}"
    echo -e "${CLR_INFO}10) Подписать сообщение ключом узла (netrum-node-sign)${CLR_RESET}"
    echo -e "${CLR_INFO}11) Зарегистрировать ноду on-chain (netrum-node-register)${CLR_RESET}"
    echo -e "${CLR_INFO}12) Запустить синхронизацию (netrum-sync)${CLR_RESET}"
    echo -e "${CLR_INFO}13) Логи синхронизации (netrum-sync-log)${CLR_RESET}"
    echo -e "${CLR_INFO}14) Запустить майнинг (netrum-mining)${CLR_RESET}"
    echo -e "${CLR_INFO}15) Логи майнинга (netrum-mining-log)${CLR_RESET}"
    echo -e "${CLR_INFO}16) Клейм наград (netrum-claim)${CLR_RESET}"
    echo -e "${CLR_INFO}17) Обновить CLI (netrum-update)${CLR_RESET}"
    echo -e "${CLR_INFO}18) Выйти из меню управления${CLR_RESET}"
    echo -ne "${CLR_WARNING}Выберите пункт: ${CLR_RESET}"
    read -r ans

    case "$ans" in
      1)  netrum-system ;;
      2)  netrum-new-wallet ;;
      3)  netrum-import-wallet ;;
      4)  netrum-wallet ;;
      5)  netrum-wallet-key ;;
      6)  netrum-wallet-remove ;;
      7)  netrum-check-basename ;;
      8)  netrum-node-id ;;
      9)  netrum-node-id-remove ;;
      10) netrum-node-sign ;;
      11) netrum-node-register ;;
      12) netrum-sync ;;
      13) netrum-sync-log ;;
      14) netrum-mining ;;
      15) netrum-mining-log ;;
      16) netrum-claim ;;
      17) netrum-update ;;
      18) break ;;
      *)  echo -e "${CLR_ERROR}Неверный выбор.${CLR_RESET}" ;;
    esac
  done
}

# ---------- Удаление ноды ----------
remove_node() {
  if [ -d "$APP_DIR" ]; then
    echo -e "${CLR_WARNING}🗑️ Удаляю $APP_DIR ...${CLR_RESET}"
    rm -rf "$APP_DIR"
    # Удалить глобальную ссылку CLI, если есть
    if command -v netrum >/dev/null 2>&1; then
      echo -e "${CLR_INFO}Удаляю глобальную ссылку CLI (npm unlink -g netrum-lite-node)...${CLR_RESET}"
      npm unlink -g netrum-lite-node >/dev/null 2>&1 || true
    fi
    echo -e "${CLR_SUCCESS}✅ Нода Netrum удалена.${CLR_RESET}"
  else
    echo -e "${CLR_WARNING}Каталог $APP_DIR не найден. Нечего удалять.${CLR_RESET}"
  fi
}

# ---------- Главное меню ----------
show_menu() {
  show_logo
  while true; do
    echo
    echo -e "${CLR_INFO}1) ⚙️  Установить зависимости${CLR_RESET}"
    echo -e "${CLR_INFO}2) 🚀 Установить и подготовить Netrum Lite Node${CLR_RESET}"
    echo -e "${CLR_INFO}3) 🧭 Управление нодой (кошелёк, регистрация, синк, майнинг, клейм, логи)${CLR_RESET}"
    echo -e "${CLR_INFO}4) 🗑️  Удалить ноду${CLR_RESET}"
    echo -e "${CLR_INFO}5) ❌ Выйти${CLR_RESET}"
    echo -ne "${CLR_WARNING}Выберите пункт: ${CLR_RESET}"
    read -r choice

    case "$choice" in
      1) install_dependencies ;;
      2) install_node ;;
      3) nodes_manage ;;
      4) remove_node ;;
      5) echo -e "${CLR_SUCCESS}👋 Выход...${CLR_RESET}"; exit 0 ;;
      *) echo -e "${CLR_ERROR}Неверный выбор. Попробуйте снова.${CLR_RESET}" ;;
    esac
  done
}

# ---------- Старт ----------
show_menu
