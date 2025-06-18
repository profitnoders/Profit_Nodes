#!/bin/bash

set -e

if [[ -z "$REWARD_ADDRESS" ]]; then
    echo "❌ REWARD_ADDRESS не задан!"
    exit 1
fi

# Скачиваем и запускаем официальный скрипт
curl -L https://github.com/cysic-labs/cysic-phase3/releases/download/v1.0.0/setup_linux.sh -o /opt/cysic/setup_linux.sh
chmod +x /opt/cysic/setup_linux.sh
/opt/cysic/setup_linux.sh "$REWARD_ADDRESS"

cd /root/cysic-verifier
bash start.sh

