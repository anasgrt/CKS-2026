#!/bin/bash
# Setup for Question 04 - RBAC Role

set -e

# Create namespace
kubectl create namespace cicd-ns --dry-run=client -o yaml | kubectl apply -f -

# Create some resources for testing
kubectl run test-pod --image=nginx --namespace=cicd-ns --restart=Never --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# Create output directory
mkdir -p /opt/course/04

echo "Environment ready!"
echo "Namespace: cicd-ns"
