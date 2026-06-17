#!/bin/bash
set -e

REGION="us-east-1"
CLUSTER="cluster-tasks-alb"
SERVICE="service-tasks-alb"
ALB_URL="http://tasks-alb-160832135.us-east-1.elb.amazonaws.com"

for arg in "$@"; do
  case $arg in
    cluster=*) CLUSTER="${arg#*=}" ;;
    service=*) SERVICE="${arg#*=}" ;;
    url=*)     ALB_URL="${arg#*=}" ;;
    region=*)  REGION="${arg#*=}" ;;
  esac
done

DIR="$(cd "$(dirname "$0")" && pwd)"
PING_URL="$ALB_URL/api/ping"
DATE=$(date -u '+%Y%m%d-%H%M%S')
LOG="$DIR/monitor-${DATE}.log"
REPORT="$DIR/zero-downtime-report-$(date -u '+%Y%m%d').md"

echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  Deploy Completo com Teste de Zero Downtime             │"
echo "  ├─────────────────────────────────────────────────────────┤"
echo "  │  Cluster : $CLUSTER"
echo "  │  Service : $SERVICE"
echo "  │  URL     : $ALB_URL"
echo "  │  Log     : $LOG"
echo "  │  Relatório: $REPORT"
echo "  └─────────────────────────────────────────────────────────┘"
echo ""
read -p "  Confirma? (s/N): " CONFIRM
[[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]] && echo "  Cancelado." && exit 0

# ─── 1. Inicia monitoramento em background ────────────────────────────────────
echo ""
echo "  📡 Iniciando monitoramento de disponibilidade..."
bash "$DIR/monitor.sh" "$PING_URL" "$LOG" &
MONITOR_PID=$!
echo "  Monitor PID: $MONITOR_PID (log: $LOG)"
sleep 3  # coleta baseline antes do deploy

# ─── 2. Build & Push ──────────────────────────────────────────────────────────
echo ""
echo "  🚀 Build + Push para ECR..."
bash "$DIR/build.sh"

# ─── 3. Force deploy ──────────────────────────────────────────────────────────
echo ""
echo "  📦 Forçando novo deployment no ECS..."
aws ecs update-service \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --force-new-deployment \
  --query 'service.deployments[0].{status:rolloutState,taskDef:taskDefinition}' \
  --output table

# ─── 4. Aguarda estabilização ─────────────────────────────────────────────────
echo ""
echo "  ⏳ Aguardando deployment completar (pode levar ~5 min)..."
aws ecs wait services-stable \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --services "$SERVICE"
echo "  ✅ Serviço estável!"

# Coleta mais alguns checks pós-deploy
sleep 15

# ─── 5. Para o monitor ────────────────────────────────────────────────────────
kill "$MONITOR_PID" 2>/dev/null || true
rm -f "${LOG}.pid"
echo ""
echo "  🛑 Monitoramento encerrado. Total de amostras: $(grep -v '^#' "$LOG" | wc -l)"

# ─── 6. Gera relatório ────────────────────────────────────────────────────────
echo ""
echo "  📝 Gerando relatório..."
bash "$DIR/gerar-relatorio.sh" "$LOG" "$ALB_URL" "$REPORT"

# ─── 7. Exibe relatório ───────────────────────────────────────────────────────
echo ""
glow --width 120 "$REPORT"

echo ""
echo "  📄 Arquivo salvo: $REPORT"
