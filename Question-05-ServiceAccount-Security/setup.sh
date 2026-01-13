#!/bin/bash
# Setup for Question 05 - ServiceAccount Security

set -e

# Create namespace
kubectl create namespace secure-ns --dry-run=client -o yaml | kubectl apply -f -

# Create insecure deployment
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: insecure-app
  namespace: secure-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: insecure-app
  template:
    metadata:
      labels:
        app: insecure-app
    spec:
      # Uses default SA with token mounted
      containers:
      - name: app
        image: nginx
        ports:
        - containerPort: 80
EOF

# Create output directory
mkdir -p /opt/course/05

echo "Environment ready!"
echo "Namespace: secure-ns"
echo "Deployment: insecure-app (using default SA with token mounted)"
