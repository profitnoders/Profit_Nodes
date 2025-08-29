#!/usr/bin/env bash
set -euo pipefail

# v2.7
# ================== базовые пути ==================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_SCRIPT="$SCRIPT_DIR/run_rl_swarm_new.sh"   # целевой раннер
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/autorun.log"
PID_FILE="$LOG_DIR/autorun.pgid"               # тут именно PGID/leader PID
CONFIG_FILE="$SCRIPT_DIR/.autorun_gensyn.conf" # модель/время/HF/PRG
mkdir -p "$LOG_DIR"

CMD_PATTERN="python -m rgym_exp.runner.swarm_launcher"
CHECK_INTERVAL=60
WARMUP_SEC=30
COOLDOWN_SEC=20
LAST_RESTART=0
SUPPRESS_UNTIL=0

# ================== флаги сигналов ==================
INT_FIRED=0
BUSY=0

# ================== утилиты ==================
echo_ts(){ echo "[$(date +'%F %T')] $*"; }
mask_token(){ [ -n "${HF_TOKEN:-}" ] && echo "set" || echo "none"; }

kill_group_by_pgid(){
  local pg="$1" name="${2:-group}"
  [ -z "$pg" ] && return
  echo_ts ">> SIGTERM группе $name PGID=$pg"
  kill -TERM -"$pg" 2>/dev/null || true
  for _ in 1 2 3; do ps -o pgid= -p "$pg" >/dev/null 2>&1 || break; sleep 1; done
  if ps -o pgid= -p "$pg" >/dev/null 2>&1; then
    echo_ts ">> SIGKILL группе $name PGID=$pg"
    kill -KILL -"$pg" 2>/dev/null || true
  fi
}

kill_by_pattern(){
  local pat="$1" timeout="${2:-10}"
  local pids; pids="$(pgrep -f "$pat" || true)"
  if [ -n "$pids" ]; then
    echo_ts ">> TERM по '$pat' (PIDs: $pids)"
    kill $pids 2>/dev/null || true
    for _ in $(seq 1 "$timeout"); do pgrep -f "$pat" >/dev/null || break; sleep 1; done
    pgrep -f "$pat" >/dev/null && { echo_ts ">> KILL по '$pat'"; pkill -9 -f "$pat" 2>/dev/null || true; }
  fi
}

# ================== память настроек ==================
save_config(){
  umask 177
  {
    printf 'MODEL_NAME=%q\n'  "${MODEL_NAME:-}"
    printf 'IDLE_MIN=%q\n'    "${IDLE_MIN:-10}"
    printf 'HF_TOKEN=%q\n'    "${HF_TOKEN:-}"
    printf 'PRG_GAME=%q\n'    "${PRG_GAME:-true}"
  } > "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE" 2>/dev/null || true
  echo_ts ">> Сохранил настройки в $CONFIG_FILE"
}
load_config(){
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  export MODEL_NAME IDLE_MIN HF_TOKEN PRG_GAME
  if [[ "${PRG_GAME:-true}" == "false" ]]; then PRG_ANSWER="n"; else PRG_ANSWER="Y"; PRG_GAME="true"; fi
  export PRG_ANSWER
}

# ================== меню стоп ==================
stop_all(){
  echo_ts "== Полная остановка autorun/swarm =="
  if [ -f "$PID_FILE" ]; then
    pg="$(cat "$PID_FILE" 2>/dev/null || true)"
    [ -n "$pg" ] && kill_group_by_pgid "$pg" "swarm"
    rm -f "$PID_FILE" || true
  fi
  kill_by_pattern "$CMD_PATTERN"
  kill_by_pattern "$RUN_SCRIPT"
  pkill -f 'swarm|autorun' 2>/dev/null || true
  sleep 2
  pgrep -f 'swarm|autorun' >/dev/null && pkill -9 -f 'swarm|autorun' 2>/dev/null || true
  echo_ts "== Готово =="
}

# ================== интерактив ==================
select_model(){
  echo ">> Модель:"
  echo "   [1] Gensyn/Qwen2.5-0.5B-Instruct (по умолчанию)"
  echo "   [2] Qwen/Qwen3-0.6B"
  echo "   [3] nvidia/AceInstruct-1.5B        ⚠️ требовательная"
  echo "   [4] dnotitia/Smoothie-Qwen3-1.7B   ⚠️ требовательная"
  echo "   [5] Gensyn/Qwen2.5-1.5B-Instruct   ⚠️ требовательная"
  read -r -p "Введите 1–5: " c; c="${c:-1}"
  case "$c" in
    2) MODEL_NAME="Qwen/Qwen3-0.6B" ;;
    3) MODEL_NAME="nvidia/AceInstruct-1.5B" ;;
    4) MODEL_NAME="dnotitia/Smoothie-Qwen3-1.7B" ;;
    5) MODEL_NAME="Gensyn/Qwen2.5-1.5B-Instruct" ;;
    *) MODEL_NAME="Gensyn/Qwen2.5-0.5B-Instruct" ;;
  esac
  export MODEL_NAME
  echo_ts ">> Модель: $MODEL_NAME"
}
select_idle(){
  echo ">> Интервал простоя лога (мин): [1]6 [2]7 [3]10* [4]12 [5]15"
  read -r -p "Введите 1–5: " t; t="${t:-3}"
  case "$t" in
    1) IDLE_MIN=6;; 2) IDLE_MIN=7;; 3) IDLE_MIN=10;; 4) IDLE_MIN=12;; 5) IDLE_MIN=15;; *) IDLE_MIN=10;;
  esac
  export IDLE_MIN
  echo_ts ">> Порог простоя: $IDLE_MIN мин."
}
select_hf(){ read -r -s -p ">> Вставьте HF токен (или Enter, чтобы пропустить): " HF_TOKEN; echo; export HF_TOKEN; }
select_prg(){
  read -r -p ">> Участвовать в AI Prediction Market? [Y/n]: " prg; prg="${prg:-Y}"
  if [[ "$prg" =~ ^[Nn]$ ]]; then PRG_GAME="false"; PRG_ANSWER="n"; else PRG_GAME="true"; PRG_ANSWER="Y"; fi
  export PRG_GAME PRG_ANSWER; echo_ts ">> PRG участие: $PRG_GAME"
}
collect_or_load(){
  if [ -f "$CONFIG_FILE" ]; then
    echo_ts ">> Найдены сохранённые настройки."
    # shellcheck disable=SC1090
    source "$CONFIG_FILE" || true
    echo "   1) модель: ${MODEL_NAME:-unset}"
    echo "   2) время:  ${IDLE_MIN:-unset} мин"
    echo "   3) HF:     $( [ -n "${HF_TOKEN:-}" ] && echo set || echo none )"
    echo "   4) PRG:    ${PRG_GAME:-unset}"
    read -r -p "Использовать сохранённые? [Y/n]: " use; use="${use:-Y}"
    if [[ "$use" =~ ^[Yy]$ ]]; then load_config; echo_ts ">> Использую сохранённые (PRG=$PRG_GAME, HF=$(mask_token))"; return; fi
  else
    echo_ts ">> Первый запуск — соберу настройки и сохраню."
  fi
  select_model; select_idle; select_hf; select_prg; save_config
}

# ================== запуск swarm (без tee!) ==================
restart_node(){
  local now; now=$(date +%s)
  if (( now - LAST_RESTART < COOLDOWN_SEC )); then echo_ts ">> Пропускаю перезапуск: cooldown ${COOLDOWN_SEC}s"; return; fi

  echo_ts ">>> Перезапуск RL-сворма…"
  # гасим предыдущую группу, если была
  if [ -f "$PID_FILE" ]; then
    old="$(cat "$PID_FILE" 2>/dev/null || true)"; [ -n "$old" ] && kill_group_by_pgid "$old" "swarm"; rm -f "$PID_FILE" || true
  fi
  kill_by_pattern "$CMD_PATTERN"
  kill_by_pattern "$RUN_SCRIPT"

  # ответы для интерактива run_rl_swarm_new.sh:
  # HF (y/n) + token → модель → PRG [Y/n] — см. скрипт раннера :contentReference[oaicite:4]{index=4} :contentReference[oaicite:5]{index=5} :contentReference[oaicite:6]{index=6}
  local answers=""
  if [ -n "${HF_TOKEN:-}" ]; then answers+="y"$'\n'"$HF_TOKEN"$'\n'; else answers+="n"$'\n'; fi
  answers+="${MODEL_NAME}"$'\n'
  answers+="${PRG_ANSWER}"$'\n'

  # ВАЖНО: создаём новую сессию и ПИШЕМ leader PID в $PID_FILE изнутри.
  setsid bash -c '
    echo $$ > '"$PID_FILE"';
    # окружение для дочерних
    export HUGGINGFACE_ACCESS_TOKEN='"'"$HF_TOKEN"'"' MODEL_NAME='"'"$MODEL_NAME"'"' PRG_GAME='"'"$PRG_GAME"'"';
    # скармливаем ответы раннеру; лог — простым редиректом без tee
    printf "%s" '"$(printf %q "$answers")"' | '"$RUN_SCRIPT"' >> '"$LOG_FILE"' 2>&1
  ' &

  # отметим время и дадим «прогреться»
  LAST_RESTART=$now
  SUPPRESS_UNTIL=$(( now + WARMUP_SEC ))
  echo_ts ">>> Процесс-группа swarm leader PID/PGID: $(cat "$PID_FILE" 2>/dev/null || echo unknown)"
}

# ================== обработка сигналов ==================
on_int(){
  [ "$BUSY" -eq 1 ] && return; BUSY=1
  if [ "$INT_FIRED" -eq 0 ]; then
    INT_FIRED=1; trap 'exit 0' INT
    echo_ts "== Ctrl+C: останавливаю только swarm (ещё раз Ctrl+C — выход) =="
    [ -f "$PID_FILE" ] && { pg="$(cat "$PID_FILE" 2>/dev/null || true)"; [ -n "$pg" ] && kill_group_by_pgid "$pg" "swarm"; rm -f "$PID_FILE" || true; }
    BUSY=0; return
  fi
  exit 0
}
on_term(){
  echo_ts "== SIGTERM: полное завершение =="
  [ -f "$PID_FILE" ] && { pg="$(cat "$PID_FILE" 2>/dev/null || true)"; [ -n "$pg" ] && kill_group_by_pgid "$pg" "swarm"; rm -f "$PID_FILE" || true; }
  exit 0
}
trap on_int INT
trap on_term TERM

# ================== меню ==================
echo ">> Что сделать?"
echo "   [1] Запустить авторан"
echo "   [2] Остановить авторан (убить все процессы swarm/autorun)"
read -r -p "Выбор [1/2]: " ACTION; ACTION="${ACTION:-1}"
[ "$ACTION" = "2" ] && { stop_all; exit 0; }

# ================== запуск ==================
collect_or_load
IDLE_THRESHOLD=$((IDLE_MIN * 60))
echo_ts "=== Запускаю цикл автозапуска ==="
restart_node

# ================== мониторинг ==================
while true; do
  now=$(date +%s)

  # прогрев
  if (( now < SUPPRESS_UNTIL )); then sleep 1; continue; fi

  # A) жив ли swarm (по PGID), иначе — перезапуск
  if [ -f "$PID_FILE" ]; then
    pg="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [ -z "$pg" ] || ! ps -o pgid= -p "$pg" >/dev/null 2>&1; then
      echo_ts "!!! Swarm-группа не найдена — перезапуск."
      restart_node; sleep "$CHECK_INTERVAL"; continue
    fi
  else
    # нет PID_FILE — подождём до конца прогрева, потом перезапустим
    echo_ts "!!! Нет $PID_FILE — ожидаю/перезапущу при следующей проверке."
    restart_node; sleep "$CHECK_INTERVAL"; continue
  fi

  # B) активность лога
  if [ -f "$LOG_FILE" ]; then
    last_mod=$(stat -c %Y "$LOG_FILE"); idle=$((now - last_mod))
    if [ "$idle" -ge "$IDLE_THRESHOLD" ]; then
      echo_ts "!!! Лог не обновлялся $((idle/60)) мин — перезапуск."
      restart_node
    fi
  else
    echo_ts "!!! Лог-файл отсутствует — жду появления."
  fi

  sleep "$CHECK_INTERVAL"
done

