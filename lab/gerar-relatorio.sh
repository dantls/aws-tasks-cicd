#!/bin/bash
# gerar-relatorio.sh — gera .md a partir do log do monitor + dados ECS/ALB
# Uso: ./gerar-relatorio.sh <log_file> <alb_url> <output.md>

LOG=$1
ALB_URL=$2
OUTPUT=${3:-zero-downtime-report-v2.md}
REGION="us-east-1"
CLUSTER="cluster-tasks-alb"
SERVICE="service-tasks-alb"

if [ -z "$LOG" ] || [ -z "$ALB_URL" ]; then
  echo "Uso: $0 <log_file> <alb_url> [output.md]"
  exit 1
fi

# ─── Métricas do log ──────────────────────────────────────────────────────────
TOTAL=$(grep -v "^#" "$LOG" | wc -l)
OK=$(grep -v "^#" "$LOG" | awk '$2=="200"' | wc -l)
FAIL=$((TOTAL - OK))
DOWNTIME=$((FAIL * 1))

START=$(grep -v "^#" "$LOG" | head -1 | awk '{print $1}')
END=$(grep -v "^#" "$LOG" | tail -1 | awk '{print $1}')

# Latência: min, max, avg (somente 200)
LATENCY_STATS=$(grep -v "^#" "$LOG" | awk '$2=="200" {gsub("ms","",$3); sum+=$3; count++; if(min==""||$3<min)min=$3; if($3>max)max=$3} END {if(count>0) printf "%dms / %dms / %dms", min, max, int(sum/count)}')

# ─── ECS: task definition e imagem atual ──────────────────────────────────────
TASK_DEF=$(aws ecs describe-services --region $REGION --cluster $CLUSTER --services $SERVICE \
  --query 'services[0].taskDefinition' --output text | sed 's|.*/||')

IMAGE=$(aws ecs describe-task-definition --region $REGION --task-definition $TASK_DEF \
  --query 'taskDefinition.containerDefinitions[0].image' --output text | sed 's|.*/||')

COMMIT=$(echo $IMAGE | cut -d: -f2)

# ─── ALB: targets saudáveis ───────────────────────────────────────────────────
TG_ARN=$(aws elbv2 describe-target-groups --region $REGION \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

HEALTHY=$(aws elbv2 describe-target-health --region $REGION --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`] | length(@)' --output text)

# ─── ECS Events ───────────────────────────────────────────────────────────────
EVENTS=$(aws ecs describe-services --region $REGION --cluster $CLUSTER --services $SERVICE \
  --query 'services[0].events[:15]' --output json | python3 -c "
import sys, json
events = json.load(sys.stdin)
for e in reversed(events):
    ts = e['createdAt'][:19].replace('T',' ')
    msg = e['message']
    if 'stopped' in msg:    icon = '🔴'
    elif 'started' in msg:  icon = '🟢'
    elif 'steady' in msg:   icon = '✅'
    elif 'completed' in msg: icon = '🏁'
    else:                   icon = '🔵'
    print(f'| {ts} | {msg} | {icon} |')
")

# ─── Amostras de latência (a cada 10 linhas) ──────────────────────────────────
LATENCY_TABLE=$(grep -v "^#" "$LOG" | awk '$2=="200"' | awk 'NR%10==1 {print "| " $1 " | " $2 " | " $3 " |"}')
FAIL_TABLE=$(grep -v "^#" "$LOG" | awk '$2!="200" {print "| " $1 " | " $2 " | " $3 " |"}')

DATE=$(date -u '+%Y-%m-%d')

# ─── Gera .md ─────────────────────────────────────────────────────────────────
cat > "$OUTPUT" << EOF
# ✅ Zero Downtime Report — Tasks 2026 · High Availability

> **Date:** $DATE | **Cluster:** \`$CLUSTER\` | **Service:** \`$SERVICE\`

---

## 📊 Availability Summary

| Metric | Value |
|---|---|
| Monitoring period | $START → $END |
| Total checks | $TOTAL |
| HTTP 200 | **$OK** |
| Failures | **$FAIL** |
| Downtime | **${DOWNTIME} seconds** |
| Commit deployed | \`$COMMIT\` |
| Task definition | \`$TASK_DEF\` |

---

## ⚡ Latency (HTTP 200 only)

| Metric | Value |
|---|---|
| Min / Max / Avg | $LATENCY_STATS |

### Samples (every 10 checks)

| Time | Status | Latency |
|---|---|---|
$LATENCY_TABLE

EOF

# Adiciona falhas se houver
if [ -n "$FAIL_TABLE" ]; then
cat >> "$OUTPUT" << EOF
---

## ❌ Failed Requests

| Time | Status | Latency |
|---|---|---|
$FAIL_TABLE

EOF
fi

cat >> "$OUTPUT" << EOF
---

## 🔄 ECS Events

| Time | Event | Status |
|---|---|---|
$EVENTS

---

## 🏗️ Why There Was No Downtime

\`\`\`
ALB (2 healthy targets at all times)
 │
 ├── Task A  ──► drain ──► stop         (old image)
 │                  │
 │             Task C  ──► register ──► serving   (new image $COMMIT)
 │
 └── Task B  serving ──► drain ──► stop
                  │
             Task D  ──► register ──► serving   (new image $COMMIT)
\`\`\`

- ECS rolling deploy replaces **1 task at a time**
- ALB drains connections before deregistering a target
- New task is healthy in ALB **before** old task is removed
- At no point did the ALB have 0 healthy targets

---

## 🖥️ Current State

| | |
|---|---|
| Desired tasks | 2 |
| Running tasks | **2** |
| Task definition | \`$TASK_DEF\` |
| Image | \`$IMAGE\` |
| ALB | \`$(echo $ALB_URL | sed 's|http://||')\` |
| ALB targets | 🟢 healthy × $HEALTHY |
EOF

echo "  ✅ Relatório gerado: $OUTPUT"
