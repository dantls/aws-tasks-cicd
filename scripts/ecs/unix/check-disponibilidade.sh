#!/bin/bash
URL=$1
TIMEOUT=${2:-120}
INTERVAL=5

if [ -z "$URL" ]; then
  echo "Uso: $0 <url> [timeout_segundos]"
  exit 1
fi

echo "Verificando disponibilidade: $URL"
echo "Timeout: ${TIMEOUT}s"

ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
  if [ "$STATUS" = "200" ]; then
    echo "✅ Disponível! HTTP $STATUS (${ELAPSED}s)"
    exit 0
  fi
  echo "⏳ HTTP $STATUS — aguardando... (${ELAPSED}s)"
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo "❌ Timeout após ${TIMEOUT}s — serviço indisponível"
exit 1
