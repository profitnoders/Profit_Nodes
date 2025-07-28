#!/bin/bash

source ~/.aztec_node_config

while true; do
  if ! docker ps --format '{{.Image}} {{.Names}}' | grep -q aztec; then
    echo "[`date`] 🔁 Контейнер Aztec не найден — перезапускаем..."

    aztec start --node --archiver --sequencer \
      --network alpha-testnet \
      --l1-rpc-urls "$ETHEREUM_HOSTS" \
      --l1-consensus-host-urls "$L1_CONSENSUS_HOST_URLS" \
      --sequencer.validatorPrivateKeys "$VALIDATOR_PRIVATE_KEYS" \
      --sequencer.publisherPrivateKey "$PUBLISHER_PRIVATE_KEY" \
      --sequencer.coinbase "$COINBASE" \
      --p2p.p2pIp "$P2P_IP"
  else
    echo "[`date`] ✅ Контейнер работает"
  fi
  echo "[`date`] ❌ Aztec завершился — перезапуск через 30 сек" 
  sleep 30 
done
