#!/usr/bin/env bash
set -euo pipefail

# 2.9
# ================== базовые пути ==================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_SCRIPT="$SCRIPT_DIR/run_rl_swarm.sh"    # целевой раннер
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/autorun.log"
CONFIG_FILE="$SCRIPT_DIR/.autorun_gensyn.conf"  # модель/время/HF/PRG
mkdir -p "$LOG_DIR"

# Мониторим по этим шаблонам (живость)
CMD_PATTERN="python -m rgym_exp.runner.swarm_launcher"
SELF_PATTERN="$RUN_SCRIPT"

CHECK_INTERVAL=60             # период проверки
WARMUP_SEC=60                 # не перезапускать сразу после старта
COOLDOWN_SEC=15               # не перезапускать чаще, чем раз в N сек
LAST_RESTART=0
SUPPRESS_UNTIL=0

# ================== утилиты ==================
echo_ts(){ echo "[$(date +'%F %T')] $*"; }
mask_token(){ [ -n "${HF_TOKEN:-}" ] && echo "set" || echo "none"; }

list_swarm_autorun(){
  # список сторонних процессов со словами swarm|autorun (кроме этого скрипта и grep)
  pgrep -af 'swarm|autorun' 2>/dev/null | grep -v -E "(grep|autorun_gensyn\.sh)" || true
}

kill_soft_then_hard(){
  local pat="$1" timeout="${2:-10}" pids
  pids="$(pgrep -f "$pat" || true)"
  [ -z "$pids" ] && return
  echo_ts ">> TERM по '$pat' (PIDs: $pids)"
  kill $pids 2>/dev/null || true
  for _ in $(seq 1 "$timeout"); do pgrep -f "$pat" >/dev/null || break; sleep 1; done
  if pgrep -f "$pat" >/dev/null; then
    echo_ts ">> KILL по '$pat'"
    pkill -9 -f "$pat" 2>/dev/null || true
  fi
}

stop_all(){
  echo_ts "== Полная остановка: swarm/autorun =="
  kill_soft_then_hard "$CMD_PATTERN"
  kill_soft_then_hard "$SELF_PATTERN"
  # широкий гребень напоследок — на случай залипших хвостов
  kill_soft_then_hard 'swarm|autorun' 5
  echo_ts "== Готово =="
}

# ================== «память» настроек ==================
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

# ================== предварительная проверка ==================
precheck_swarm_autorun(){
  local existing
  existing="$(list_swarm_autorun)"
  if [ -n "$existing" ]; then
    echo_ts "!!! Найдены уже запущенные процессы (swarm|autorun):"
    echo "$existing"
    read -r -p "Убить их сейчас и продолжить? [Y/n]: " ans; ans="${ans:-Y}"
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      # сначала прицельно, потом широкий гребень
      kill_soft_then_hard "$CMD_PATTERN"
      kill_soft_then_hard "$SELF_PATTERN"
      kill_soft_then_hard 'swarm|autorun' 5
      echo_ts ">> Остатки убраны."
    else
      echo_ts ">> Выход без запуска."
      exit 0
    fi
  fi
}

# ================== запуск swarm ==================
restart_node(){
  local now; now=$(date +%s)
  if (( now - LAST_RESTART < COOLDOWN_SEC )); then echo_ts ">> Пропускаю перезапуск: cooldown ${COOLDOWN_SEC}s"; return; fi

  echo_ts ">>> Перезапуск RL-сворма…"
  # убираем потенциальные хвосты предыдущих запусков
  kill_soft_then_hard "$CMD_PATTERN"
  kill_soft_then_hard "$SELF_PATTERN"

  # ответы для интерактива run_rl_swarm_new.sh:
  # HF(y/n)+token → модель → PRG [Y/n] (см. сам раннер: HF, модель и PRG спрашиваются по очереди):contentReference[oaicite:1]{index=1}
  local answers=""
  if [ -n "${HF_TOKEN:-}" ]; then answers+="y"$'\n'"$HF_TOKEN"$'\n'; else answers+="n"$'\n'; fi
  answers+="${MODEL_NAME}"$'\n'
  answers+="${PRG_ANSWER}"$'\n'

  # без setsid/tee — простое фоновое выполнение; лог редиректом
  (
    printf "%s" "$answers" | bash -lc \
    "exec '$RUN_SCRIPT' 2>&1 | stdbuf -oL -eL tee -a '$LOG_FILE'"
  ) &


  LAST_RESTART=$now
  SUPPRESS_UNTIL=$(( now + WARMUP_SEC ))
  echo_ts ">>> Запущено. Прогрев ${WARMUP_SEC}s…"
}

# ================== трапы (одноразовые) ==================
CLEANING_UP=0
cleanup_once(){
  [ "$CLEANING_UP" -eq 1 ] && exit 0
  CLEANING_UP=1
  trap - INT TERM
  echo_ts "== Сигнал: останавливаю процессы (swarm/autorun) =="
  stop_all
  exit 0
}
trap cleanup_once INT TERM

# ================== меню ==================
echo ">> Что сделать?"
echo "   [1] Запустить авторан"
echo "   [2] Остановить авторан (убить все процессы swarm/autorun)"
read -r -p "Выбор [1/2]: " ACTION; ACTION="${ACTION:-1}"
if [ "$ACTION" = "2" ]; then stop_all; exit 0; fi

# ================== запуск ==================
precheck_swarm_autorun          # <— твоя новая логика
collect_or_load
IDLE_THRESHOLD=$((IDLE_MIN * 60))

echo_ts "=== Запускаю цикл автозапуска ==="
restart_node

# ================== мониторинг ==================
while true; do
  now=$(date +%s)

  # прогрев
  if (( now < SUPPRESS_UNTIL )); then sleep 1; continue; fi

  # A) жив ли процесс (по паттернам)
  if ! pgrep -f "$CMD_PATTERN" >/dev/null && ! pgrep -f "$SELF_PATTERN" >/dev/null; then
    echo_ts "!!! Не вижу swarm — перезапуск"
    restart_node
    sleep "$CHECK_INTERVAL"
    continue
  fi

  # B) активность лога
  if [ -f "$LOG_FILE" ]; then
    last_mod=$(stat -c %Y "$LOG_FILE")
    idle=$((now - last_mod))
    if [ "$idle" -ge "$IDLE_THRESHOLD" ]; then
      echo_ts "!!! Лог не обновлялся $((idle/60)) мин — перезапуск"
      restart_node
    fi
  else
    echo_ts "!!! Лог-файл отсутствует — жду появления"
  fi

  sleep "$CHECK_INTERVAL"
done
