#!/bin/bash
# Setup for Question 12 - Kubesec Analysis

set -e

# Install kubesec if not present
if ! command -v kubesec &> /dev/null; then
    echo "Installing kubesec..."
    # Download latest kubesec binary
    curl -sSL https://github.com/controlplaneio/kubesec/releases/download/v2.14.0/kubesec_linux_amd64.tar.gz -o /tmp/kubesec.tar.gz
    tar -xzf /tmp/kubesec.tar.gz -C /tmp
    sudo mv /tmp/kubesec /usr/local/bin/
    sudo chmod +x /usr/local/bin/kubesec
    rm -f /tmp/kubesec.tar.gz
    echo "kubesec installed successfully."
fi

# Verify kubesec is working
if command -v kubesec &> /dev/null; then
    echo "kubesec version: $(kubesec version 2>/dev/null || echo 'installed')"
else
    echo "WARNING: kubesec installation may have failed. You can use Docker instead:"
    echo "  docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin < <manifest.yaml>"
fi

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
