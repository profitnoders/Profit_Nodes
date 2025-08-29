#!/usr/bin/env bash
set -euo pipefail

# v2.4
# ======================================
# Пути и базовые настройки
# ======================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_SCRIPT="$SCRIPT_DIR/run_rl_swarm_new.sh"   # целевой раннер
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/autorun.log"
PID_FILE="$LOG_DIR/autorun.pid"
CONFIG_FILE="$SCRIPT_DIR/.autorun_gensyn.conf" # модель/время/HF/PRG

CMD_PATTERN="python -m rgym_exp.runner.swarm_launcher"
CHECK_INTERVAL=60
mkdir -p "$LOG_DIR"

# ======================================
# Флаги
# ======================================
INT_FIRED=0       # было ли первое Ctrl+C
BUSY=0            # защита от реэнтранса

# ======================================
# Утилиты
# ======================================
echo_ts(){ echo "[$(date +'%F %T')] $*"; }

kill_group_by_pgid(){
  # $1 = PGID, $2 = имя для лога
  local pg="$1" name="${2:-group}"
  [ -z "$pg" ] && return
  echo_ts ">> Завершаю процесс-группу $name PGID=$pg (TERM)"
  kill -TERM -"$pg" 2>/dev/null || true
  for _ in 1 2 3; do
    ps -o pgid= -p "$pg" >/dev/null 2>&1 || break
    sleep 1
  done
  if ps -o pgid= -p "$pg" >/dev/null 2>&1; then
    echo_ts ">> Группа $name PGID=$pg ещё жива — KILL"
    kill -KILL -"$pg" 2>/dev/null || true
  fi
}

kill_by_pattern(){
  local pat="$1" timeout="${2:-10}" pids
  pids="$(pgrep -f "$pat" || true)"
  if [ -n "$pids" ]; then
    echo_ts ">> SIGTERM по '$pat' (PIDs: ${pids})"
    kill ${pids} 2>/dev/null || true
    for _ in $(seq 1 "$timeout"); do
      pgrep -f "$pat" >/dev/null || break
      sleep 1
    done
    if pgrep -f "$pat" >/dev/null; then
      echo_ts ">> Живы после SIGTERM — SIGKILL по '$pat'"
      pkill -9 -f "$pat" 2>/dev/null || true
    fi
  fi
}

mask_token(){ [ -n "${HF_TOKEN:-}" ] && echo "set" || echo "none"; }

# ======================================
# «Память» настроек
# ======================================
save_config(){
  umask 177
  {
    printf 'MODEL_NAME=%q\n'  "${MODEL_NAME:-}"
    printf 'IDLE_MIN=%q\n'    "${IDLE_MIN:-10}"
    printf 'HF_TOKEN=%q\n'    "${HF_TOKEN:-}"
    printf 'PRG_GAME=%q\n'    "${PRG_GAME:-true}"
  } > "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE" 2>/dev/null || true
  echo_ts ">> Настройки сохранены в $CONFIG_FILE (600)."
}

load_config(){
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  export MODEL_NAME IDLE_MIN HF_TOKEN PRG_GAME
  if [[ "${PRG_GAME:-true}" == "false" ]]; then
    PRG_ANSWER="n"
  else
    PRG_ANSWER="Y"; PRG_GAME="true"
  fi
  export PRG_ANSWER
}

# ======================================
# Меню «Остановить всё»
# ======================================
stop_all(){
  echo_ts "== Останавливаю авторан и все процессы с 'swarm'/'autorun' =="
  if [ -f "$PID_FILE" ]; then
    pgid="$(cat "$PID_FILE" 2>/dev/null || true)"
    [ -n "$pgid" ] && kill_group_by_pgid "$pgid" "swarm"
    rm -f "$PID_FILE" || true
  fi
  kill_by_pattern "$CMD_PATTERN"
  kill_by_pattern "$RUN_SCRIPT"
  pkill -f 'swarm|autorun' 2>/dev/null || true
  sleep 2
  if pgrep -f 'swarm|autorun' >/dev/null; then
    echo_ts ">> Остатки найдены — SIGKILL по 'swarm|autorun'"
    pkill -9 -f 'swarm|autorun' 2>/dev/null || true
  fi
  echo_ts "== Готово =="
}

# ======================================
# Интерактив (модель, время, HF, PRG)
# ======================================
select_model_interactive(){
  echo ">> Выберите модель:"
  echo "   [1] Gensyn/Qwen2.5-0.5B-Instruct (по умолчанию)"
  echo "   [2] Qwen/Qwen3-0.6B"
  echo "   [3] nvidia/AceInstruct-1.5B        ⚠️ требовательная"
  echo "   [4] dnotitia/Smoothie-Qwen3-1.7B   ⚠️ требовательная"
  echo "   [5] Gensyn/Qwen2.5-1.5B-Instruct   ⚠️ требовательная"
  read -r -p "Введите 1–5: " choice
  choice="${choice:-1}"
  case "$choice" in
    2) MODEL_NAME="Qwen/Qwen3-0.6B" ;;
    3) MODEL_NAME="nvidia/AceInstruct-1.5B" ;;
    4) MODEL_NAME="dnotitia/Smoothie-Qwen3-1.7B" ;;
    5) MODEL_NAME="Gensyn/Qwen2.5-1.5B-Instruct" ;;
    *) MODEL_NAME="Gensyn/Qwen2.5-0.5B-Instruct" ;;
  esac
  export MODEL_NAME
  echo_ts ">> Модель: $MODEL_NAME"
}

select_idle_threshold_interactive(){
  echo ">> Интервал простоя лога (мин): [1]6 [2]7 [3]10* [4]12 [5]15"
  read -r -p "Введите 1–5: " thr_choice
  thr_choice="${thr_choice:-3}"
  case "$thr_choice" in
    1) IDLE_MIN=6 ;;
    2) IDLE_MIN=7 ;;
    3) IDLE_MIN=10 ;;
    4) IDLE_MIN=12 ;;
    5) IDLE_MIN=15 ;;
    *) IDLE_MIN=10 ;;
  esac
  export IDLE_MIN
  echo_ts ">> Порог простоя: $IDLE_MIN мин."
}

select_hf_token_interactive(){
  read -r -s -p ">> Вставьте Hugging Face токен (или Enter, чтобы пропустить): " HF_TOKEN
  echo
  export HF_TOKEN
}

select_prg_interactive(){
  read -r -p ">> Участвовать в AI Prediction Market? [Y/n]: " prg
  prg="${prg:-Y}"
  if [[ "$prg" =~ ^[Nn]$ ]]; then
    PRG_GAME="false"; PRG_ANSWER="n"
  else
    PRG_GAME="true";  PRG_ANSWER="Y"
  fi
  export PRG_GAME PRG_ANSWER
  echo_ts ">> PRG участие: $PRG_GAME"
}

collect_or_load_settings(){
  if [ -f "$CONFIG_FILE" ]; then
    echo_ts ">> Найдены сохранённые настройки:"
    # shellcheck disable=SC1090
    source "$CONFIG_FILE" || true
    echo "   1) модель: ${MODEL_NAME:-unset}"
    echo "   2) время:  ${IDLE_MIN:-unset} мин"
    echo "   3) HF:     $( [ -n "${HF_TOKEN:-}" ] && echo set || echo none )"
    echo "   4) PRG:    ${PRG_GAME:-unset}"
    read -r -p "Использовать сохранённые данные? [Y/n]: " use_saved
    use_saved="${use_saved:-Y}"
    if [[ "$use_saved" =~ ^[Yy]$ ]]; then
      load_config
      echo_ts ">> Использую сохранённые (PRG=${PRG_GAME}, HF=$(mask_token))"
      return
    fi
  else
    echo_ts ">> Первый запуск — соберу настройки и сохраню."
  fi
  select_model_interactive
  select_idle_threshold_interactive
  select_hf_token_interactive
  select_prg_interactive
  save_config
}

# ======================================
# Старт swarm (с перезапуском)
# ======================================
restart_node(){
  echo_ts ">>> Перезапуск RL-сворма..."
  if [ -f "$PID_FILE" ]; then
    pgid_old="$(cat "$PID_FILE" 2>/dev/null || true)"
    [ -n "$pgid_old" ] && kill_group_by_pgid "$pgid_old" "swarm"
    rm -f "$PID_FILE" || true
  fi
  kill_by_pattern "$CMD_PATTERN"
  kill_by_pattern "$RUN_SCRIPT"

  # ответы для run_rl_swarm_new.sh: HF(y/n)+token, модель, PRG(Y/n)
  local answers=""
  if [ -n "${HF_TOKEN:-}" ]; then
    answers+="y"$'\n'"$HF_TOKEN"$'\n'
  else
    answers+="n"$'\n'
  fi
  answers+="${MODEL_NAME}"$'\n'
  answers+="${PRG_ANSWER}"$'\n'

  echo_ts ">>> Старт: $RUN_SCRIPT (model=$MODEL_NAME, idle=${IDLE_MIN}m, HF=$(mask_token), PRG=$PRG_GAME)"

  (
    printf "%s" "$answers" | \
    setsid -w bash -lc "HUGGINGFACE_ACCESS_TOKEN=\"$HF_TOKEN\" MODEL_NAME=\"$MODEL_NAME\" PRG_GAME=\"$PRG_GAME\" exec '$RUN_SCRIPT' 2>&1 | stdbuf -oL -eL tee -a '$LOG_FILE'"
  ) &

  local child_pid pgid
  child_pid=$!
  pgid="$(ps -o pgid= -p "$child_pid" | tr -d ' ' || true)"
  [ -n "$pgid" ] && echo "$pgid" > "$PID_FILE"
  echo_ts ">>> Процесс-группа swarm: PGID=${pgid:-unknown}"
}

# ======================================
# Обработка сигналов
# ======================================
on_int(){
  # защита от повторного входа
  if [ "$BUSY" -eq 1 ]; then return; fi
  BUSY=1

  if [ "$INT_FIRED" -eq 0 ]; then
    INT_FIRED=1
    # 2-е Ctrl+C должно завершить autorun немедленно — меняем ловушку
    trap 'exit 0' INT
    echo_ts "== Ctrl+C: останавливаю только swarm (ещё раз Ctrl+C — выйти) =="
    if [ -f "$PID_FILE" ]; then
      pgid="$(cat "$PID_FILE" 2>/dev/null || true)"
      [ -n "$pgid" ] && kill_group_by_pgid "$pgid" "swarm"
      rm -f "$PID_FILE" || true
    fi
    BUSY=0
    return
  fi

  # если почему-то сюда дошли — на всякий случай выходим
  exit 0
}

on_term(){
  echo_ts "== SIGTERM: полное завершение =="
  if [ -f "$PID_FILE" ]; then
    pgid="$(cat "$PID_FILE" 2>/dev/null || true)"
    [ -n "$pgid" ] && kill_group_by_pgid "$pgid" "swarm"
    rm -f "$PID_FILE" || true
  fi
  exit 0
}

trap on_int INT
trap on_term TERM

# ======================================
# Меню действий
# ======================================
echo ">> Что сделать?"
echo "   [1] Запустить авторан"
echo "   [2] Остановить авторан (убить все процессы swarm/autorun)"
read -r -p "Выбор [1/2]: " ACTION
ACTION="${ACTION:-1}"
if [ "$ACTION" = "2" ]; then
  stop_all
  exit 0
fi

# ======================================
# Сбор/загрузка настроек
# ======================================
collect_or_load_settings
IDLE_THRESHOLD=$((IDLE_MIN * 60))

# ======================================
# Первый запуск
# ======================================
echo_ts "=== Запускаю цикл автозапуска ==="
restart_node

# ======================================
# Основной цикл мониторинга
# ======================================
while true; do
  now=$(date +%s)
  # A) жив ли процесс (python-раннер или сам run-скрипт)
  if ! pgrep -f "$CMD_PATTERN" >/dev/null && ! pgrep -f "$RUN_SCRIPT" >/dev/null; then
    echo_ts "!!! Процесс умер — перезапуск..."
    restart_node
    sleep "$CHECK_INTERVAL"
    continue
  fi
  # B) активность лога
  if [ -f "$LOG_FILE" ]; then
    last_mod=$(stat -c %Y "$LOG_FILE")
    idle=$((now - last_mod))
    if [ "$idle" -ge "$IDLE_THRESHOLD" ]; then
      echo_ts "!!! Лог не обновлялся $((idle/60)) мин — перезапуск."
      restart_node
    fi
  else
    echo_ts "!!! Лог-файл '$LOG_FILE' не найден — перезапуск."
    restart_node
  fi
  sleep "$CHECK_INTERVAL"
done

