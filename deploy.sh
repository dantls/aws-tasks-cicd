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

echo "🚀 Iniciando deploy..."
./build.sh

echo "📦 Forçando novo deployment no ECS..."
aws ecs update-service --cluster $CLUSTER --service $SERVICE --force-new-deployment --region $REGION

echo "✅ Deploy concluído!"
