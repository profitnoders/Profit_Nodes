#!/usr/bin/env bash

set -euo pipefail

# —————————————
# 0) Выбор модели
# —————————————
echo ">> Выберите модель для запуска:"
echo "   [1] Gensyn/Qwen2.5-0.5B-Instruct (по-умолчанию)"
echo "   [2] Qwen/Qwen3-0.6B"
read -p "Введите цифру 1 или 2 и нажмите Enter: " choice
choice=${choice:-1}

case "$choice" in
  2)
    MODEL_NAME="Qwen/Qwen3-0.6B"
    ;;
  *)
    MODEL_NAME="Gensyn/Qwen2.5-0.5B-Instruct"
    ;;
esac

export MODEL_NAME
echo ">> Выбранная модель: $MODEL_NAME"
echo

# —————————————
# 1) Настройки
# —————————————
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_SCRIPT="$SCRIPT_DIR/run_rl_swarm.sh"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/autorun.log"
CMD_PATTERN="python -m rgym_exp.runner.swarm_launcher"

echo "[$(date +'%F %T')] >> Выберите интервал проверки простоя лога (в минутах):"
echo "   [1] 6"
echo "   [2] 7"
echo "   [3] 10 (по умолчанию)"
echo "   [4] 12"
echo "   [5] 15"
read -p "[$(date +'%F %T')] Введите цифру 1–5 и нажмите Enter: " thr_choice
thr_choice=${thr_choice:-2}

case "$thr_choice" in
  1) IDLE_MIN=6 ;;
  2) IDLE_MIN=7 ;;
  3) IDLE_MIN=10 ;;
  4) IDLE_MIN=12 ;;
  5) IDLE_MIN=15 ;;
  *) IDLE_MIN=10 ;;
esac

# переводим минуты в секунды
IDLE_THRESHOLD=$((IDLE_MIN * 60))
echo "[$(date +'%F %T')] >> Лог будет считаться «зависшим» после $IDLE_MIN минут простоя."
echo

CHECK_INTERVAL=60

mkdir -p "$LOG_DIR"

restart_node() {
  echo "[$(date +'%F %T')] >>> Перезапуск RL-сворма..."

  # Останавливаем старый процесс, если есть
  pids=$(pgrep -f "$CMD_PATTERN" || true)
  if [ -n "$pids" ]; then
    echo "[$(date +'%F %T')]     Найдены PID для остановки: $pids"
    kill $pids
    echo "[$(date +'%F %T')]     Отправлен SIGTERM, ожидаю завершения..."
    while pgrep -f "$CMD_PATTERN" >/dev/null; do
      sleep 1
    done
    echo "[$(date +'%F %T')]     Старая сессия завершена."
  else
    echo "[$(date +'%F %T')]     Старые процессы не найдены."
  fi

  # Запускаем новую ноду
  echo "[$(date +'%F %T')]     Запускаю: $RUN_SCRIPT"
  bash -lc "exec '$RUN_SCRIPT' 2>&1 | tee -a '$LOG_FILE'" &
}

# -------------------------
# 2) Первый запуск
# -------------------------
echo "[$(date +'%F %T')] === Запускаем цикл автозапуска ==="
restart_node

# -------------------------
# 3) Основной цикл мониторинга
# -------------------------
while true; do
  now=$(date +%s)

  # A) Проверяем, жив ли процесс
  # A) Проверяем, жив ли процесс Python *или* сам run_rl_swarm.sh
  if ! pgrep -f "$CMD_PATTERN" >/dev/null && ! pgrep -f "$RUN_SCRIPT" >/dev/null; then
    echo "[$(date +'%F %T')] !!! Process died — restarting..."
    restart_node
    sleep "$CHECK_INTERVAL"
    continue
  fi


  # B) Проверяем активность лога
  if [ -f "$LOG_FILE" ]; then
    last_mod=$(stat -c %Y "$LOG_FILE")
    idle=$((now - last_mod))
    if [ "$idle" -ge "$IDLE_THRESHOLD" ]; then
      echo "[$(date +'%F %T')] !!! Лог не обновлялся $((idle/60)) мин — перезапускаем."
      restart_node
    fi
  else
    echo "[$(date +'%F %T')] !!! Лог-файл '$LOG_FILE' не найден — перезапускаем."
    restart_node
  fi

  sleep "$CHECK_INTERVAL"
done
