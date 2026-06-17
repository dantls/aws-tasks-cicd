#!/bin/bash
ECR_REGISTRY="071680046842.dkr.ecr.us-east-1.amazonaws.com"
COMMIT=$(git -C "$(dirname "$0")/.." rev-parse --short HEAD)
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY
docker build -t tasks "$PROJECT_ROOT"
docker tag tasks:latest $ECR_REGISTRY/tasks:latest
docker tag tasks:latest $ECR_REGISTRY/tasks:$COMMIT
docker push $ECR_REGISTRY/tasks:latest
docker push $ECR_REGISTRY/tasks:$COMMIT

echo "  Image pushed: tasks:latest + tasks:$COMMIT"
