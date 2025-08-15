#!/bin/bash

SESSION="prover"
CMD="cd ~/cysic-prover && ./start.sh"

while true; do
    if ! screen -list | grep -q "$SESSION"; then
        echo "Restarting screen session..."
        screen -dmS "$SESSION" bash -c "$CMD"
    fi
    sleep 20
done
