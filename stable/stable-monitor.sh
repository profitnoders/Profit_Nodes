#!/bin/bash

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Stable Node Resource Monitor
# Мониторинг ресурсов ноды Stable
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Цвета и стили
RED='\033[0;31m'
BRIGHT_RED='\033[1;31m'
GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
ORANGE='\033[38;5;208m'
BLUE='\033[0;34m'
BRIGHT_BLUE='\033[1;34m'
PURPLE='\033[0;35m'
MAGENTA='\033[1;35m'
CYAN='\033[0;36m'
BRIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
NC='\033[0m' # No Color

# Розовый цвет для логотипа (как у Profit Nodes)
PINK='\033[38;5;198m'
PINK2='\033[38;5;199m'

# Конфигурация
NODE_DIR="/root/.stabled"
SERVICE_NAME="stabled"
RPC_PORT="26657"
P2P_PORT="26656"

# Функция определения портов из config.toml
detect_ports() {
  if [ ! -f "$NODE_DIR/config/config.toml" ]; then
    return
  fi
  
  # RPC порт - ищем laddr в секции [rpc]
  # Примеры: laddr = "tcp://127.0.0.1:26657" или laddr = "tcp://0.0.0.0:26667"
  local rpc_line=$(awk '/^\[rpc\]/,/^\[/ {if (/^laddr =/) print}' "$NODE_DIR/config/config.toml" | head -1)
  if [ -n "$rpc_line" ]; then
    CUSTOM_RPC=$(echo "$rpc_line" | grep -oP ':\d+' | grep -oP '\d+' | tail -1)
    if [ -n "$CUSTOM_RPC" ] && [ "$CUSTOM_RPC" != "0" ]; then
      RPC_PORT="$CUSTOM_RPC"
    fi
  fi
  
  # P2P порт - ищем laddr в секции [p2p]
  # Пример: laddr = "tcp://0.0.0.0:26656" или "tcp://0.0.0.0:26666"
  local p2p_line=$(awk '/^\[p2p\]/,/^\[/ {if (/^laddr =/) print}' "$NODE_DIR/config/config.toml" | head -1)
  if [ -n "$p2p_line" ]; then
    CUSTOM_P2P=$(echo "$p2p_line" | grep -oP ':\d+' | grep -oP '\d+' | tail -1)
    if [ -n "$CUSTOM_P2P" ] && [ "$CUSTOM_P2P" != "0" ]; then
      P2P_PORT="$CUSTOM_P2P"
    fi
  fi
}

# Определяем порты при запуске
detect_ports

# Функция для отрисовки красивого градиентного прогресс-бара (ASCII версия)
draw_bar() {
  local percent=$1
  local width=30
  local filled=$((percent * width / 100))
  local empty=$((width - filled))
  
  # Выбор цвета с градиентом
  local color=$BRIGHT_GREEN
  
  if [ $percent -ge 90 ]; then
    color=$BRIGHT_RED
  elif [ $percent -ge 80 ]; then
    color=$RED
  elif [ $percent -ge 70 ]; then
    color=$ORANGE
  elif [ $percent -ge 60 ]; then
    color=$YELLOW
  elif [ $percent -ge 40 ]; then
    color=$BRIGHT_GREEN
  else
    color=$BRIGHT_CYAN
  fi
  
  # Отрисовка бара с ASCII символами
  printf "${GRAY}[${NC}${color}"
  printf "%${filled}s" | tr ' ' '='
  printf "${NC}${DIM}"
  printf "%${empty}s" | tr ' ' '-'
  printf "${NC}${GRAY}]${NC} ${BOLD}%3d%%${NC}" $percent
}

# Функция для форматирования байтов
format_bytes() {
  local bytes=$1
  if [ $bytes -ge 1073741824 ]; then
    echo "$(awk "BEGIN {printf \"%.2f GB\", $bytes/1073741824}")"
  elif [ $bytes -ge 1048576 ]; then
    echo "$(awk "BEGIN {printf \"%.2f MB\", $bytes/1048576}")"
  elif [ $bytes -ge 1024 ]; then
    echo "$(awk "BEGIN {printf \"%.2f KB\", $bytes/1024}")"
  else
    echo "${bytes} B"
  fi
}

# Функция очистки экрана и заголовок
show_header() {
  clear
  
  # Красивый логотип
  echo -e "${PINK}  ███████╗████████╗ █████╗ ██████╗ ██╗     ███████╗${NC}"
  echo -e "${PINK2}  ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝${NC}"
  echo -e "${PINK}  ███████╗   ██║   ███████║██████╔╝██║     █████╗  ${NC}"
  echo -e "${PINK2}  ╚════██║   ██║   ██╔══██║██╔══██╗██║     ██╔══╝  ${NC}"
  echo -e "${PINK}  ███████║   ██║   ██║  ██║██████╔╝███████╗███████╗${NC}"
  echo -e "${PINK2}  ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝${NC}"
  echo ""
  echo -e "${BRIGHT_CYAN}+===============================================================================+${NC}"
  echo -e "${BRIGHT_CYAN}|${NC} ${BOLD}${WHITE} REAL-TIME RESOURCE MONITOR${NC}                                                ${BRIGHT_CYAN}|${NC}"
  echo -e "${BRIGHT_CYAN}|${NC} ${DIM}${GRAY}Press ${WHITE}Ctrl+C${GRAY} to exit${NC}                                                           ${BRIGHT_CYAN}|${NC}"
  echo -e "${BRIGHT_CYAN}+===============================================================================+${NC}"
  echo ""
}

# Функция получения статуса ноды
get_node_status() {
  echo -e "${MAGENTA}+-----------------------------------------------------------------------------+${NC}"
  echo -e "${MAGENTA}|${NC} ${BOLD}${BRIGHT_CYAN} NODE STATUS${NC}                                                                ${MAGENTA}|${NC}"
  echo -e "${MAGENTA}+-----------------------------------------------------------------------------+${NC}"
  
  # Проверка статуса сервиса
  if systemctl is-active --quiet $SERVICE_NAME; then
    echo -e "  ${GREEN}●${NC} Service:        ${GREEN}${BOLD}RUNNING${NC}"
    
    # Получаем данные через RPC
    STATUS_JSON=$(curl -s --connect-timeout 2 localhost:${RPC_PORT}/status 2>/dev/null)
    NET_JSON=$(curl -s --connect-timeout 2 localhost:${RPC_PORT}/net_info 2>/dev/null)
    
    if [ -n "$STATUS_JSON" ] && echo "$STATUS_JSON" | jq -e . >/dev/null 2>&1; then
      CATCHING_UP=$(echo "$STATUS_JSON" | jq -r '.result.sync_info.catching_up' 2>/dev/null)
      LATEST_HEIGHT=$(echo "$STATUS_JSON" | jq -r '.result.sync_info.latest_block_height' 2>/dev/null)
      LATEST_TIME=$(echo "$STATUS_JSON" | jq -r '.result.sync_info.latest_block_time' 2>/dev/null)
      
      if [ "$CATCHING_UP" == "false" ]; then
        echo -e "  ${BRIGHT_GREEN}✅${NC} Sync Status:    ${BRIGHT_GREEN}${BOLD}SYNCED${NC}"
      else
        echo -e "  ${YELLOW}🔄${NC} Sync Status:    ${YELLOW}${BOLD}SYNCING...${NC}"
      fi
      
      echo -e "  ${BLUE}▪${NC} Block Height:   ${WHITE}${BOLD}${LATEST_HEIGHT:-N/A}${NC}"
      
      # Форматируем время
      if [ -n "$LATEST_TIME" ] && [ "$LATEST_TIME" != "null" ]; then
        FORMATTED_TIME=$(date -d "$LATEST_TIME" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$LATEST_TIME")
        echo -e "  ${BLUE}▪${NC} Block Time:     ${GRAY}${FORMATTED_TIME}${NC}"
      fi
    else
      echo -e "  ${YELLOW}⚠${NC} RPC Status:     ${YELLOW}NOT RESPONDING (port ${RPC_PORT})${NC}"
    fi
    
    # Пиры
    if [ -n "$NET_JSON" ]; then
      N_PEERS=$(echo "$NET_JSON" | jq -r '.result.n_peers' 2>/dev/null)
      if [ "$N_PEERS" -ge 3 ]; then
        echo -e "  ${BRIGHT_GREEN}🌟${NC} Connected Peers: ${BRIGHT_GREEN}${BOLD}${N_PEERS}${NC} ${GREEN}(good)${NC}"
      elif [ "$N_PEERS" -gt 0 ]; then
        echo -e "  ${YELLOW}⚠️${NC}  Connected Peers: ${YELLOW}${BOLD}${N_PEERS}${NC} ${ORANGE}(low)${NC}"
      else
        echo -e "  ${BRIGHT_RED}❌${NC} Connected Peers: ${BRIGHT_RED}${BOLD}${N_PEERS}${NC} ${RED}(isolated)${NC}"
      fi
    fi
    
  else
    echo -e "  ${RED}●${NC} Service:        ${RED}${BOLD}STOPPED${NC}"
  fi
  echo ""
}

# Функция отображения CPU
show_cpu() {
  echo -e "${YELLOW}+-----------------------------------------------------------------------------+${NC}"
  echo -e "${YELLOW}|${NC} ${BOLD}${ORANGE} CPU USAGE${NC}                                                                    ${YELLOW}|${NC}"
  echo -e "${YELLOW}+-----------------------------------------------------------------------------+${NC}"
  
  # Общая загрузка CPU
  CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1)
  echo -ne "  Overall:        "
  draw_bar ${CPU_USAGE:-0}
  echo ""
  
  # Загрузка процесса stabled
  if systemctl is-active --quiet $SERVICE_NAME; then
    STABLED_CPU=$(ps aux | grep "[s]tabled start" | awk '{print $3}' | cut -d'.' -f1)
    if [ -n "$STABLED_CPU" ]; then
      echo -ne "  stabled:        "
      draw_bar ${STABLED_CPU:-0}
      echo ""
    fi
  fi
  
  # Load Average
  LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)
  CORES=$(nproc)
  echo -e "  ${GRAY}Load Average:   ${WHITE}${LOAD_AVG}${GRAY} (${CORES} cores)${NC}"
  echo ""
}

# Функция отображения RAM
show_memory() {
  echo -e "${PURPLE}+-----------------------------------------------------------------------------+${NC}"
  echo -e "${PURPLE}|${NC} ${BOLD}${MAGENTA} MEMORY USAGE${NC}                                                                 ${PURPLE}|${NC}"
  echo -e "${PURPLE}+-----------------------------------------------------------------------------+${NC}"
  
  # Общая память
  MEM_INFO=$(free -m)
  MEM_TOTAL=$(echo "$MEM_INFO" | awk 'NR==2 {print $2}')
  MEM_USED=$(echo "$MEM_INFO" | awk 'NR==2 {print $3}')
  MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
  
  echo -ne "  System:         "
  draw_bar ${MEM_PERCENT}
  echo -e "  ${GRAY}(${MEM_USED} MB / ${MEM_TOTAL} MB)${NC}"
  
  # Память процесса stabled
  if systemctl is-active --quiet $SERVICE_NAME; then
    STABLED_RSS=$(ps aux | grep "[s]tabled start" | awk '{print $6}')
    if [ -n "$STABLED_RSS" ]; then
      STABLED_MB=$((STABLED_RSS / 1024))
      STABLED_PERCENT=$((STABLED_MB * 100 / MEM_TOTAL))
      echo -ne "  stabled:        "
      draw_bar ${STABLED_PERCENT}
      echo -e "  ${GRAY}(${STABLED_MB} MB)${NC}"
    fi
  fi
  
  # SWAP
  SWAP_TOTAL=$(echo "$MEM_INFO" | awk 'NR==3 {print $2}')
  SWAP_USED=$(echo "$MEM_INFO" | awk 'NR==3 {print $3}')
  if [ "$SWAP_TOTAL" -gt 0 ]; then
    SWAP_PERCENT=$((SWAP_USED * 100 / SWAP_TOTAL))
    echo -ne "  Swap:           "
    draw_bar ${SWAP_PERCENT}
    echo -e "  ${GRAY}(${SWAP_USED} MB / ${SWAP_TOTAL} MB)${NC}"
  fi
  echo ""
}

# Функция отображения диска
show_disk() {
  echo -e "${BRIGHT_BLUE}+-----------------------------------------------------------------------------+${NC}"
  echo -e "${BRIGHT_BLUE}|${NC} ${BOLD}${CYAN} DISK USAGE${NC}                                                                   ${BRIGHT_BLUE}|${NC}"
  echo -e "${BRIGHT_BLUE}+-----------------------------------------------------------------------------+${NC}"
  
  # Общее использование диска
  DISK_INFO=$(df -h / | awk 'NR==2 {print $2, $3, $5}')
  DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $1}')
  DISK_USED=$(echo "$DISK_INFO" | awk '{print $2}')
  DISK_PERCENT=$(echo "$DISK_INFO" | awk '{print $3}' | tr -d '%')
  
  echo -ne "  Root (/)        "
  draw_bar ${DISK_PERCENT}
  echo -e "  ${GRAY}(${DISK_USED} / ${DISK_TOTAL})${NC}"
  
  # Размер данных ноды
  if [ -d "$NODE_DIR" ]; then
    NODE_SIZE=$(du -sh "$NODE_DIR" 2>/dev/null | awk '{print $1}')
    echo -e "  ${GRAY}Node Data:      ${WHITE}${NODE_SIZE:-N/A}${GRAY} ($NODE_DIR)${NC}"
    
    # Детализация папок ноды
    if [ -d "$NODE_DIR/data" ]; then
      DATA_SIZE=$(du -sh "$NODE_DIR/data" 2>/dev/null | awk '{print $1}')
      echo -e "  ${GRAY}├─ data/        ${WHITE}${DATA_SIZE}${NC}"
    fi
    if [ -d "$NODE_DIR/wasm" ]; then
      WASM_SIZE=$(du -sh "$NODE_DIR/wasm" 2>/dev/null | awk '{print $1}')
      echo -e "  ${GRAY}├─ wasm/        ${WHITE}${WASM_SIZE}${NC}"
    fi
    if [ -d "$NODE_DIR/config" ]; then
      CONFIG_SIZE=$(du -sh "$NODE_DIR/config" 2>/dev/null | awk '{print $1}')
      echo -e "  ${GRAY}└─ config/      ${WHITE}${CONFIG_SIZE}${NC}"
    fi
  fi
  echo ""
}

# Функция отображения сетевой статистики
show_network() {
  echo -e "${BRIGHT_GREEN}+-----------------------------------------------------------------------------+${NC}"
  echo -e "${BRIGHT_GREEN}|${NC} ${BOLD}${GREEN} NETWORK & PORTS${NC}                                                              ${BRIGHT_GREEN}|${NC}"
  echo -e "${BRIGHT_GREEN}+-----------------------------------------------------------------------------+${NC}"
  
  # Показываем порты с индикацией кастомные или стандартные
  if [ "$P2P_PORT" == "26656" ]; then
    echo -e "  ${BLUE}▪${NC} P2P Port:       ${WHITE}${P2P_PORT}${NC} ${GRAY}(standard)${NC}"
  else
    echo -e "  ${BLUE}▪${NC} P2P Port:       ${WHITE}${P2P_PORT}${NC} ${YELLOW}(custom)${NC}"
  fi
  
  if [ "$RPC_PORT" == "26657" ]; then
    echo -e "  ${BLUE}▪${NC} RPC Port:       ${WHITE}${RPC_PORT}${NC} ${GRAY}(standard)${NC}"
  else
    echo -e "  ${BLUE}▪${NC} RPC Port:       ${WHITE}${RPC_PORT}${NC} ${YELLOW}(custom)${NC}"
  fi
  
  # Проверяем что порты слушают
  if ss -tlnp | grep -q ":${P2P_PORT}"; then
    echo -e "  ${GREEN}●${NC} P2P Listening:  ${GREEN}YES${NC}"
  else
    echo -e "  ${RED}●${NC} P2P Listening:  ${RED}NO${NC}"
  fi
  
  if ss -tlnp | grep -q ":${RPC_PORT}"; then
    echo -e "  ${GREEN}●${NC} RPC Listening:  ${GREEN}YES${NC}"
  else
    echo -e "  ${RED}●${NC} RPC Listening:  ${RED}NO${NC}"
  fi
  
  # Сетевая статистика процесса
  if systemctl is-active --quiet $SERVICE_NAME; then
    STABLED_PID=$(pgrep -f "[s]tabled start")
    if [ -n "$STABLED_PID" ]; then
      CONNECTIONS=$(ss -tnp | grep "pid=${STABLED_PID}" | wc -l)
      echo -e "  ${BLUE}▪${NC} TCP Connections: ${WHITE}${CONNECTIONS}${NC}"
    fi
  fi
  echo ""
}

# Основной цикл
show_dashboard() {
  while true; do
    show_header
    get_node_status
    show_cpu
    show_memory
    show_disk
    show_network
    
    echo -e "${MAGENTA}===============================================================================${NC}"
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${DIM}${GRAY}Last update: ${WHITE}${CURRENT_TIME}${GRAY}  |  Refresh: ${WHITE}3s${NC}"
    echo -e "${DIM}${GRAY}Tip: Press ${WHITE}Ctrl+C${GRAY} to exit the monitor${NC}"
    echo ""
    
    sleep 3
  done
}

# Проверка что запущен от root или с sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root or with sudo${NC}"
  exit 1
fi

# Проверка зависимостей
if ! command -v jq &> /dev/null; then
  echo -e "${YELLOW}Warning: jq not installed. Installing...${NC}"
  apt-get update -qq && apt-get install -y jq -qq
fi

# Запуск дашборда
show_dashboard
