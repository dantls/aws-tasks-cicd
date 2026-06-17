#!/bin/bash
# monitor.sh — monitoramento contínuo de disponibilidade e latência
# Uso: ./monitor.sh <url> <log_file>
# Para o loop: kill $(cat <log_file>.pid)

URL=$1
LOG=$2

if [ -z "$URL" ] || [ -z "$LOG" ]; then
  echo "Uso: $0 <url> <log_file>"
  exit 1
fi

echo $$ > "${LOG}.pid"
echo "# monitor started at $(date -u '+%Y-%m-%dT%H:%M:%SZ') url=$URL" > "$LOG"

while true; do
  RESULT=$(curl -s -o /dev/null -w "%{http_code} %{time_total}" --max-time 5 "$URL" 2>/dev/null || echo "000 0")
  STATUS=$(echo $RESULT | awk '{print $1}')
  LATENCY=$(echo $RESULT | awk '{printf "%.0f", $2 * 1000}')
  TS=$(date -u '+%H:%M:%S')
  echo "$TS $STATUS ${LATENCY}ms" >> "$LOG"
  sleep 1
done
