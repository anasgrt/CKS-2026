#!/bin/bash
# Setup for Question 12 - Kubesec Analysis

set -e

# Create namespace
kubectl create namespace kubesec-ns --dry-run=client -o yaml | kubectl apply -f -

# Create output directory
mkdir -p /opt/course/12

# Create insecure deployment manifest
cat > /opt/course/12/insecure-deploy.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: kubesec-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web
        image: nginx
        ports:
        - containerPort: 80
        securityContext:
          privileged: true
EOF

echo "Environment ready!"
echo "Namespace: kubesec-ns"
echo "Insecure deployment: /opt/course/12/insecure-deploy.yaml"
echo ""
echo "Run Kubesec with:"
echo "  kubesec scan /opt/course/12/insecure-deploy.yaml"
echo "  OR using Docker:"
echo "  docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin < /opt/course/12/insecure-deploy.yaml"
