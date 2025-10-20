#!/bin/bash

# Жестко задаем путь к .env и логам
ENV_FILE="/root/.irys/.env"
LOG_FILE="/root/.irys/irys_logs.log"

# Проверка: есть ли .env
if [[ ! -f "$ENV_FILE" ]]; then
    echo "❌ Нет ENV-файла по пути $ENV_FILE"
    exit 1
fi

# Подгружаем переменные
source "$ENV_FILE"

# Подставляем значения по умолчанию
DELAY_MIN=${DELAY_MIN:-10}
LONG_DELAY=${LONG_DELAY:-5}
LONG_EVERY=${LONG_EVERY:-5}
PRIVATE_KEY=${PRIVATE_KEY:-""}
RPC_URL=${RPC_URL:-"https://1rpc.io/sepolia"}

# Проверка на пустой приватник
if [[ -z "$PRIVATE_KEY" ]]; then
    echo "❌ PRIVATE_KEY не задан в .env"
    exit 1
fi

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Логирование с меткой времени
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Рандом в диапазоне ±30%
rand_range() {
    base=$1
    delta=$(( base * 30 / 100 ))
    if (( delta < 1 )); then delta=1; fi
    echo $(( base - delta + RANDOM % (2 * delta + 1) ))
}

EXTS=("txt" "jpg" "png" "doc")
COUNT=0

while true; do
    COUNT=$((COUNT + 1))
    EXT=${EXTS[$RANDOM % ${#EXTS[@]}]}
    FILE="/tmp/file_$(date +%s).$EXT"

    case "$EXT" in
        txt) base64 /dev/urandom | head -c 100 > "$FILE" ;;
        jpg) convert -size 100x100 xc:gray "$FILE" ;;
        png) convert -size 100x100 xc:blue "$FILE" ;;
        doc) echo "Random Word DOC" > "$FILE" ;;
    esac

    log "[+] Создан файл: $FILE"
    irys upload "$FILE" -n devnet -t ethereum -w "$PRIVATE_KEY" --tags "$FILE" "$EXT" --provider-url "$RPC_URL" >> "$LOG_FILE" 2>&1
    log "[+] Загружено. Удаляем файл..."
    rm -f "$FILE"

    if (( COUNT % LONG_EVERY == 0 )); then
        sleep_min=$(rand_range "$LONG_DELAY")
        log "[~] Длинная пауза $sleep_min минут..."
        sleep $((sleep_min * 60))
    else
        sleep_min=$(rand_range "$DELAY_MIN")
        log "[~] Пауза $sleep_min минут..."
        sleep $((sleep_min * 60))
    fi
done

    fi
done
