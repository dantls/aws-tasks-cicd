#!/bin/bash
set -e

REGION="us-east-1"
CLUSTER="cluster-tasks-alb"
SERVICE="service-tasks-alb"
URL="http://tasks-alb-160832135.us-east-1.elb.amazonaws.com/api/ping"

for arg in "$@"; do
  case $arg in
    cluster=*) CLUSTER="${arg#*=}" ;;
    service=*) SERVICE="${arg#*=}" ;;
    url=*)     URL="${arg#*=}" ;;
    region=*)  REGION="${arg#*=}" ;;
  esac
done

# ─── Uso ───────────────────────────────────────────────────────────────────────
# ./timeline.sh
# ./timeline.sh cluster=<c> service=<s> url=<alb_url>
# ───────────────────────────────────────────────────────────────────────────────

echo ""
echo "  ═══════════════════════════════════════════════════════════════════"
echo "  📅 DEPLOYMENT TIMELINE — $SERVICE"
echo "  ═══════════════════════════════════════════════════════════════════"

# ─── ECS Events ────────────────────────────────────────────────────────────────
echo ""
echo "  🗂  Container Events (ECS):"
echo "  ───────────────────────────────────────────────────────────────────"

aws ecs describe-services \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --query 'services[0].events[:15]' \
  --output json | python3 -c "
import sys, json
events = json.load(sys.stdin)
for e in reversed(events):
    ts = e['createdAt'][:19].replace('T',' ')
    msg = e['message']
    if 'stopped' in msg:
        icon = '🔴'
    elif 'started' in msg:
        icon = '🟢'
    elif 'steady' in msg:
        icon = '✅'
    elif 'deployment' in msg and 'completed' in msg:
        icon = '🏁'
    else:
        icon = '🔵'
    print(f'  {icon}  {ts}  {msg}')
"

# ─── ALB Health ────────────────────────────────────────────────────────────────
echo ""
echo "  🌐 ALB Target Health (now):"
echo "  ───────────────────────────────────────────────────────────────────"

TG_ARN=$(aws elbv2 describe-target-groups \
  --region "$REGION" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

aws elbv2 describe-target-health \
  --region "$REGION" \
  --target-group-arn "$TG_ARN" \
  --query 'TargetHealthDescriptions[*].{id:Target.Id,port:Target.Port,state:TargetHealth.State}' \
  --output json | python3 -c "
import sys, json
targets = json.load(sys.stdin)
for t in targets:
    icon = '🟢' if t['state'] == 'healthy' else '🔴'
    print(f\"  {icon}  {t['id']}:{t['port']}  →  {t['state']}\")
"

# ─── Live Ping ─────────────────────────────────────────────────────────────────
echo ""
echo "  📡 Live ALB response ($URL):"
echo "  ───────────────────────────────────────────────────────────────────"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
[ "$STATUS" = "200" ] && echo "  🟢  HTTP $STATUS — UP" || echo "  🔴  HTTP $STATUS — DOWN"
echo ""
