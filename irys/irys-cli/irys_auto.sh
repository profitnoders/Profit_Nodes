#!/bin/bash

source $HOME/.irys/.env

# Значения по умолчанию, если вдруг не подставились
DELAY_MIN=${DELAY_MIN:-10}
LONG_DELAY=${LONG_DELAY:-5}
LONG_EVERY=${LONG_EVERY:-5}

LOG_FILE="$HOME/.irys/irys_logs.log"

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

rand_range() {
    base=$1
    delta=$(( base * 30 / 100 ))
    if (( delta < 1 )); then
        delta=1
    fi
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

    echo "[+] Создан файл: $FILE" | tee -a "$LOG_FILE"
    irys upload "$FILE" -n devnet -t ethereum -w "$PRIVATE_KEY" --tags "$FILE" "$EXT" --provider-url "$RPC_URL" >> "$LOG_FILE" 2>&1
    echo "[+] Загружено. Удаляем файл..." | tee -a "$LOG_FILE"
    rm -f "$FILE"

    if (( COUNT % LONG_EVERY == 0 )); then
        SLEEP_MIN=$(rand_range $LONG_DELAY)
        echo "[~] Длинная пауза $SLEEP_MIN минут..." | tee -a "$LOG_FILE"
        sleep $((SLEEP_MIN * 60))
    else
        SLEEP_MIN=$(rand_range $DELAY_MIN)
        echo "[~] Пауза $SLEEP_MIN минут..." | tee -a "$LOG_FILE"
        sleep $((SLEEP_MIN * 60))
    fi
done
