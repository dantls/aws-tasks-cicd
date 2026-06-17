#!/bin/bash
set -e

REGION="us-east-1"
CLUSTER="cluster-tasks"
SERVICE="service-tasks"

# ─── Uso ───────────────────────────────────────────────────────────────────────
# ./deploy.sh
# ./deploy.sh cluster=<cluster> service=<service> [region=<region>]
# ───────────────────────────────────────────────────────────────────────────────

for arg in "$@"; do
  case $arg in
    cluster=*) CLUSTER="${arg#*=}" ;;
    service=*) SERVICE="${arg#*=}" ;;
    region=*)  REGION="${arg#*=}" ;;
  esac
done

echo ""
echo "  Cluster : $CLUSTER"
echo "  Service : $SERVICE"
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

echo ""
echo "  ✅ Deploy iniciado com sucesso!"
