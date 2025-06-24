#!/bin/bash

CLR_SUCCESS='\033[1;30;42m'
CLR_RESET='\033[0m'

generate_systemd_service() {
  for ((i = 1; i <= NODE_COUNT; i++)); do
      NODE_DIR=~/datagram_nodes/node_$i
      mkdir -p "$NODE_DIR"
      wget -qO "$NODE_DIR/datagram-cli" https://github.com/Datagram-Group/datagram-cli-release/releases/latest/download/datagram-cli-x86_64-linux
      chmod +x "$NODE_DIR/datagram-cli"

      SERVICE_FILE="/etc/systemd/system/datagram-node@$i.service"
      cat <<EOF | sudo tee "$SERVICE_FILE" >/dev/null
[Unit]
Description=Datagram Node Instance $i
After=network.target

[Service]
User=$(logname)
WorkingDirectory=$NODE_DIR
ExecStart=$NODE_DIR/datagram-cli run -- -key ${NODE_KEYS[$i]}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

      sudo systemctl daemon-reload
      sudo systemctl enable datagram-node@$i
      sudo systemctl start datagram-node@$i
      echo -e "${CLR_SUCCESS}✅ Нода #$i запущена как systemd-сервис.${CLR_RESET}"
  done
}

# Запуск только если скрипт вызван напрямую (а не source)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ -z "$NODE_COUNT" || -z "${NODE_KEYS[1]}" ]]; then
    echo -e "\033[1;31m❌ Переменные NODE_COUNT и NODE_KEYS не заданы. Запусти через основной скрипт.\033[0m"
    exit 1
  fi
  generate_systemd_service
fi
