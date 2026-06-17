#!/bin/bash
REGION="us-east-1"

for arg in "$@"; do
  case $arg in
    cluster=*) CLUSTER="${arg#*=}" ;;
    service=*) SERVICE="${arg#*=}" ;;
    region=*)  REGION="${arg#*=}" ;;
  esac
done

if [ -z "$CLUSTER" ] || [ -z "$SERVICE" ]; then
  echo "Uso: $0 cluster=<cluster> service=<service> [region=<region>]"
  exit 1
fi

echo "Parando service ECS..."
aws ecs update-service --cluster $CLUSTER --service $SERVICE --desired-count 0 --region $REGION

echo "Buscando ASG do cluster..."
CAPACITY_PROVIDER=$(aws ecs describe-clusters --clusters $CLUSTER --region $REGION \
  --query "clusters[0].capacityProviders[0]" --output text)

ASG=$(aws ecs describe-capacity-providers --capacity-providers $CAPACITY_PROVIDER --region $REGION \
  --query "capacityProviders[0].autoScalingGroupProvider.autoScalingGroupArn" --output text | xargs basename)

echo "Parando instância EC2 (ASG: $ASG)..."
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG --min-size 0 --desired-capacity 0 --region $REGION

echo "Pronto! O serviço e a instância EC2 foram parados."
