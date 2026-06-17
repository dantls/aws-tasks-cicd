#!/bin/bash
set -e

REGION="us-east-1"
CLUSTER="cluster-tasks-alb"
SERVICE="service-tasks-alb"

# ─── Uso ───────────────────────────────────────────────────────────────────────
# ./parar-ecs.sh
# ./parar-ecs.sh cluster=<cluster> service=<service> [region=<region>]
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
read -p "  ⚠️  Confirma parada do serviço e EC2? (s/N): " CONFIRM
[[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]] && echo "  Cancelado." && exit 0

# ─── Parar Service ─────────────────────────────────────────────────────────────
echo ""
echo "  Parando service ECS..."
aws ecs update-service \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --desired-count 0 \
  --query 'service.deployments[0].{status:rolloutState,desired:desiredCount}' \
  --output table

# ─── Parar EC2 via ASG ─────────────────────────────────────────────────────────
echo ""
echo "  Buscando ASG do cluster..."
CAPACITY_PROVIDER=$(aws ecs describe-clusters \
  --clusters "$CLUSTER" \
  --region "$REGION" \
  --query "clusters[0].capacityProviders[0]" \
  --output text)

ASG=$(aws ecs describe-capacity-providers \
  --capacity-providers "$CAPACITY_PROVIDER" \
  --region "$REGION" \
  --query "capacityProviders[0].autoScalingGroupProvider.autoScalingGroupArn" \
  --output text | xargs basename)

echo "  Parando instância EC2 (ASG: $ASG)..."
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "$ASG" \
  --min-size 0 \
  --desired-capacity 0 \
  --region "$REGION"

echo ""
echo "  ✅ Serviço e instância EC2 parados com sucesso!"
