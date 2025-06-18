#!/bin/bash
set -e

echo "▶ Запуск Cysic Verifier..."
if [ ! -f "/root/start.sh" ]; then
    echo "❌ Не найден start.sh в /root. Проверьте корректность инициализации!"
    exit 1
fi

chmod +x /root/start.sh
exec bash /root/start.sh
