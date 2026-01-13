#!/bin/bash
# Setup for Question 19 - Ingress TLS

set -e

# Create namespace
kubectl create namespace web-ns --dry-run=client -o yaml | kubectl apply -f -

# Create deployment and service
kubectl create deployment web-app --image=nginx --namespace=web-ns --dry-run=client -o yaml | kubectl apply -f -
kubectl expose deployment web-app --port=80 --name=web-svc --namespace=web-ns --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# Create output directory
mkdir -p /opt/course/19

# Generate self-signed certificate for testing
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /opt/course/19/tls.key \
  -out /opt/course/19/tls.crt \
  -subj "/CN=secure.example.com/O=example" 2>/dev/null

echo "Environment ready!"
echo "Namespace: web-ns"
echo "Deployment: web-app"
echo "Service: web-svc (port 80)"
echo ""
echo "TLS files created:"
echo "  Certificate: /opt/course/19/tls.crt"
echo "  Key: /opt/course/19/tls.key"
