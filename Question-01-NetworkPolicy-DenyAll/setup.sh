#!/bin/bash
# Setup for Question 01 - NetworkPolicy Default Deny

set -e

# Create namespace
kubectl create namespace isolated-ns --dry-run=client -o yaml | kubectl apply -f -

# Create test pods
kubectl run web-server --image=nginx --namespace=isolated-ns --restart=Never --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
kubectl run api-server --image=nginx --namespace=isolated-ns --restart=Never --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# Create output directory
mkdir -p /opt/course/01

echo "Environment ready!"
echo "Namespace: isolated-ns"
echo "Test pods: web-server, api-server"
