#!/bin/bash

CONFIG_FILE="$ENV_FILE"
source \$CONFIG_FILE

LOG_FILE="$LOG_FILE"

log() {
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] \$1" | tee -a "\$LOG_FILE"
}

DELAY_MIN=$1
LONG_DELAY=$2
LONG_EVERY=$3
COUNT=0

EXTS=("txt" "jpg" "png" "doc")

while true; do
    COUNT=\$((COUNT + 1))
    EXT=\${EXTS[\$RANDOM % \${#EXTS[@]}]}
    FILE="/tmp/file_\$(date +%s).\$EXT"

    case "\$EXT" in
        txt) base64 /dev/urandom | head -c 100 > "\$FILE" ;;
        jpg) convert -size 100x100 xc:gray "\$FILE" ;;
        png) convert -size 100x100 xc:blue "\$FILE" ;;
        doc) echo "Random Word DOC" > "\$FILE" ;;
    esac

    log "Создан файл: \$FILE"
    irys upload "\$FILE" -n devnet -t ethereum -w "\$PRIVATE_KEY" --tags "\$FILE" "\$EXT" --provider-url "\$RPC_URL" >> "\$LOG_FILE" 2>&1
    log "Файл загружен. Удаляем..."
    rm -f "\$FILE"

    if (( COUNT % LONG_EVERY == 0 )); then
        log "Длинная пауза \$LONG_DELAY минут..."
        sleep \$((LONG_DELAY * 60))
    else
        log "Пауза \$DELAY_MIN минут..."
        sleep \$((DELAY_MIN * 60))
    fi
done
