#!/bin/bash
set -e

BASE_URL=$1

# ─── Uso ───────────────────────────────────────────────────────────────────────
# ./verificar-disponibilidade.sh <base_url>
# Ex: ./verificar-disponibilidade.sh http://meu-alb.amazonaws.com
# ───────────────────────────────────────────────────────────────────────────────

if [ -z "$BASE_URL" ]; then
  echo "  Uso: $0 <base_url>"
  echo "  Ex : $0 http://meu-alb.amazonaws.com"
  exit 1
fi

BASE_URL="${BASE_URL%/}"  # remove trailing slash

PASS=0
FAIL=0

check() {
  local LABEL=$1
  local URL=$2
  local EXPECTED=${3:-200}

  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
  BODY=$(curl -s "$URL")

  if [ "$STATUS" = "$EXPECTED" ]; then
    printf "  ✅ %-30s HTTP %s\n" "$LABEL" "$STATUS"
    PASS=$((PASS + 1))
  else
    printf "  ❌ %-30s HTTP %s (esperado %s)\n" "$LABEL" "$STATUS" "$EXPECTED"
    echo "     Resposta: $BODY"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "  Base URL : $BASE_URL"
echo "  ─────────────────────────────────────────────────────────────────────"

# ─── Checks ────────────────────────────────────────────────────────────────────
check "ping"         "$BASE_URL/api/ping"
check "versao"       "$BASE_URL/api/versao"
check "tarefas (DB)" "$BASE_URL/api/tarefas"

# ─── Resultado ─────────────────────────────────────────────────────────────────
echo "  ─────────────────────────────────────────────────────────────────────"
echo "  Resultado: $PASS passou(aram) | $FAIL falhou(aram)"
echo ""

[ $FAIL -gt 0 ] && exit 1 || exit 0
