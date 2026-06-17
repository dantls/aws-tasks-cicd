#!/bin/bash
set -e

REGION="us-east-1"
CLUSTER="cluster-tasks"

# ─── Uso ───────────────────────────────────────────────────────────────────────
# ./rollback.sh --no-alb
# ./rollback.sh --alb
# ───────────────────────────────────────────────────────────────────────────────

MODE=""
DIRECT_COMMIT=""
for arg in "$@"; do
  case $arg in
    --no-alb) MODE="no-alb" ;;
    --alb)    MODE="alb"    ;;
    *)        DIRECT_COMMIT="$arg" ;;
  esac
done

if [ -z "$MODE" ]; then
  echo "Uso: $0 --no-alb | --alb [commit]"
  exit 1
fi

if [ "$MODE" = "alb" ]; then
  SERVICE="service-tasks-alb"
  TASK_FAMILY="task-def-tasks-alb"
else
  SERVICE="service-tasks"
  TASK_FAMILY="task-def-tasks"
fi

# ─── Resolução direta por commit ──────────────────────────────────────────────
if [ -n "$DIRECT_COMMIT" ]; then
  TARGET=$(aws ecs list-task-definitions \
    --region "$REGION" \
    --family-prefix "$TASK_FAMILY" \
    --status ACTIVE \
    --query 'taskDefinitionArns' \
    --output json | python3 -c "
import sys, json, subprocess
arns = json.load(sys.stdin)
for arn in arns:
    img = subprocess.check_output(['aws','ecs','describe-task-definition','--region','$REGION','--task-definition',arn,'--query','taskDefinition.containerDefinitions[0].image','--output','text']).decode().strip()
    if img.endswith(':$DIRECT_COMMIT'):
        print(arn)
        break
")
  if [ -z "$TARGET" ]; then
    echo "  Commit '$DIRECT_COMMIT' não encontrado."
    exit 1
  fi
  echo ""
  echo "  Revertendo para commit: $DIRECT_COMMIT"
  echo "  Task def: $TARGET"
  read -p "  Confirma? (s/N): " CONFIRM
  [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]] && echo "  Cancelado." && exit 0
  aws ecs update-service \
    --region "$REGION" \
    --cluster "$CLUSTER" \
    --service "$SERVICE" \
    --task-definition "$TARGET" \
    --query 'service.deployments[0].{status:rolloutState,taskDef:taskDefinition}' \
    --output table
  echo ""
  echo "  Rollback iniciado com sucesso!"
  exit 0
fi

# ─── Listar revisões ativas ────────────────────────────────────────────────────
echo ""
echo "  Revisões disponíveis para: $TASK_FAMILY"
echo "  ─────────────────────────────────────────────────────────────────────"
printf "  %-6s %-20s %-65s\n" "Rev" "Commit (imagem)" "Task Definition ARN"
echo "  ─────────────────────────────────────────────────────────────────────"

ARNS=$(aws ecs list-task-definitions \
  --region "$REGION" \
  --family-prefix "$TASK_FAMILY" \
  --status ACTIVE \
  --sort DESC \
  --query 'taskDefinitionArns' \
  --output json)

declare -a REV_LIST
i=1
while IFS= read -r ARN; do
  ARN=$(echo "$ARN" | tr -d '",' | xargs)
  [ -z "$ARN" ] && continue

  REV=$(echo "$ARN" | grep -oP ':\d+$' | tr -d ':')
  IMAGE=$(aws ecs describe-task-definition \
    --region "$REGION" \
    --task-definition "$ARN" \
    --query 'taskDefinition.containerDefinitions[0].image' \
    --output text)
  TAG=$(echo "$IMAGE" | grep -oP ':[^:]+$' | tr -d ':')

  printf "  %-6s %-20s %-65s\n" "[$i]" "$TAG" "$ARN"
  REV_LIST[$i]="$ARN"
  ((i++))
done < <(echo "$ARNS" | python3 -c "import sys,json; [print(x) for x in json.load(sys.stdin)]")

echo "  ─────────────────────────────────────────────────────────────────────"
echo ""

# ─── Revisão atual ─────────────────────────────────────────────────────────────
CURRENT=$(aws ecs describe-services \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --query 'services[0].taskDefinition' \
  --output text)
echo "  Service atual: $SERVICE"
echo "  Task def atual: $CURRENT"
echo ""

# ─── Seleção ───────────────────────────────────────────────────────────────────
read -p "  Escolha o número para rollback: " CHOICE

TARGET="${REV_LIST[$CHOICE]}"
if [ -z "$TARGET" ]; then
  echo "  Opção inválida."
  exit 1
fi

echo ""
echo "  Revertendo para: $TARGET"
read -p "  Confirma? (s/N): " CONFIRM
[[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]] && echo "  Cancelado." && exit 0

# ─── Rollback ──────────────────────────────────────────────────────────────────
echo ""
aws ecs update-service \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --task-definition "$TARGET" \
  --query 'service.deployments[0].{status:rolloutState,taskDef:taskDefinition}' \
  --output table

echo ""
echo "  Rollback iniciado com sucesso!"
