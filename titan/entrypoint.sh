#!/usr/bin/env bash
set -euo pipefail

: "${TITAN_KEY:?TITAN_KEY is required}"

SERVER_URL="${SERVER_URL:-https://fil-agent-server-api.titannet.io}"
WORKDIR="${WORKDIR:-/data}"

if [[ -n "${PROXY:-}" ]]; then
  # Вводишь login:pass@ip:port или socks5://...
  if [[ "$PROXY" != *"://"* ]]; then
    PROXY_URL="http://${PROXY}"
  else
    PROXY_URL="${PROXY}"
  fi

  export http_proxy="$PROXY_URL"
  export https_proxy="$PROXY_URL"
  export HTTP_PROXY="$PROXY_URL"
  export HTTPS_PROXY="$PROXY_URL"
  export all_proxy="$PROXY_URL"
  export ALL_PROXY="$PROXY_URL"
fi

mkdir -p "$WORKDIR"

exec /opt/filtitanagent/filagent \
  --working-dir="$WORKDIR" \
  --server-url="$SERVER_URL" \
  --key="$TITAN_KEY"
