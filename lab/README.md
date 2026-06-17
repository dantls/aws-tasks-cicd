# 🚀 Lab Scripts — Tasks 2026 · High Availability

> Cluster: `cluster-tasks-alb` | Service: `service-tasks-alb` | ALB: `tasks-alb-160832135.us-east-1.elb.amazonaws.com`

## Scripts

| Script | Descrição | Uso |
|---|---|---|
| `build.sh` | Build da imagem Docker e push para ECR | `./build.sh` |
| `deploy.sh` | Deploy no ECS (sem ALB) | `./deploy.sh [cluster=<c>] [service=<s>]` |
| `deploy-alb.sh` | Build → Deploy → Aguarda → Timeline | `./deploy-alb.sh url=<alb_url>` |
| `rollback.sh` | Rollback por commit hash ou interativo | `./rollback.sh --alb [commit]` |
| `parar-ecs.sh` | Para o service e instância EC2 via ASG | `./parar-ecs.sh [cluster=<c>] [service=<s>]` |
| `timeline.sh` | Exibe eventos de containers + saúde do ALB | `./timeline.sh` |
| `verificar-disponibilidade.sh` | Testa `/api/ping`, `/api/versao`, `/api/tarefas` | `./verificar-disponibilidade.sh <base_url>` |
| `check-disponibilidade.sh` | Aguarda URL retornar HTTP 200 | `./check-disponibilidade.sh <url> [timeout]` |

## Fluxo de Deploy com High Availability

```
git commit → ./deploy-alb.sh url=http://<alb>
                │
                ├── build.sh          (build + push ECR com tag do commit)
                ├── ecs update-service (rolling deploy — 2 tasks)
                ├── ecs wait stable    (aguarda conclusão)
                └── timeline.sh        (mostra eventos + ALB health)
```

## Rollback

```bash
# Interativo — lista revisões disponíveis
./rollback.sh --alb

# Direto por commit
./rollback.sh --alb abc1234
```
