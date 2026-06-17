ECR_REGISTRY="071680046842.dkr.ecr.us-east-1.amazonaws.com"
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY
docker build -t tasks .
docker tag tasks:latest $ECR_REGISTRY/tasks:latest
docker push $ECR_REGISTRY/tasks:latest
