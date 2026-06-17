#!/bin/bash
set -e

URL=$1
TIMEOUT=${2:-120}
INTERVAL=5

# ─── Uso ───────────────────────────────────────────────────────────────────────
# ./check-disponibilidade.sh <url> [timeout_segundos]
# ───────────────────────────────────────────────────────────────────────────────

if [ -z "$URL" ]; then
  echo "  Uso: $0 <url> [timeout_segundos]"
  exit 1
fi

echo ""
echo "  URL     : $URL"
echo "  Timeout : ${TIMEOUT}s"
echo "  ─────────────────────────────────────────────────────────────────────"

ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
  if [ "$STATUS" = "200" ]; then
    echo ""
    echo "  ✅ Disponível! HTTP $STATUS (${ELAPSED}s)"
    exit 0
  fi
  printf "  ⏳ HTTP %-4s — aguardando... (%ss)\n" "$STATUS" "$ELAPSED"
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo ""
echo "  ❌ Timeout após ${TIMEOUT}s — serviço indisponível"
exit 1
