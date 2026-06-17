#!/bin/bash
set -e

REGION="us-east-1"
CLUSTER="cluster-tasks-alb"
SERVICE="service-tasks-alb"
URL=""

# ─── Uso ───────────────────────────────────────────────────────────────────────
# ./deploy-alb.sh url=<alb_url>
# ./deploy-alb.sh cluster=<cluster> service=<service> url=<alb_url> [region=<region>]
# ───────────────────────────────────────────────────────────────────────────────

for arg in "$@"; do
  case $arg in
    cluster=*) CLUSTER="${arg#*=}" ;;
    service=*) SERVICE="${arg#*=}" ;;
    url=*)     URL="${arg#*=}" ;;
    region=*)  REGION="${arg#*=}" ;;
  esac
done

if [ -z "$URL" ]; then
  echo "  Erro: url= é obrigatório"
  echo "  Uso: $0 url=<alb_url> [cluster=<c>] [service=<s>] [region=<r>]"
  exit 1
fi

echo ""
echo "  Cluster : $CLUSTER"
echo "  Service : $SERVICE"
echo "  URL     : $URL"
echo "  Region  : $REGION"
echo ""
read -p "  Confirma deploy? (s/N): " CONFIRM
[[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]] && echo "  Cancelado." && exit 0

# ─── Build & Push ──────────────────────────────────────────────────────────────
echo ""
echo "  🚀 Iniciando build..."
./build.sh

# ─── Deploy ────────────────────────────────────────────────────────────────────
echo ""
echo "  📦 Forçando novo deployment no ECS..."
aws ecs update-service \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --force-new-deployment \
  --query 'service.deployments[0].{status:rolloutState,taskDef:taskDefinition}' \
  --output table

# ─── Aguardar Deployment Completar ────────────────────────────────────────────
echo ""
echo "  ⏳ Aguardando deployment completar..."
aws ecs wait services-stable \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --services "$SERVICE"

# ─── Timeline ──────────────────────────────────────────────────────────────────
DIR="$(cd "$(dirname "$0")" && pwd)"
"$DIR/timeline.sh" cluster="$CLUSTER" service="$SERVICE" url="$URL" region="$REGION"
