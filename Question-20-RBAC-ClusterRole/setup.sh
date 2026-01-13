#!/bin/bash
# Setup for Question 20 - RBAC ClusterRole

set -e

# Create namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Create test pods in different namespaces
kubectl create namespace test-ns1 --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace test-ns2 --dry-run=client -o yaml | kubectl apply -f -
kubectl run test-pod1 --image=nginx -n test-ns1 --restart=Never --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
kubectl run test-pod2 --image=nginx -n test-ns2 --restart=Never --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# Create output directory
mkdir -p /opt/course/20

echo "Environment ready!"
echo "Monitoring namespace: monitoring"
echo "Test namespaces: test-ns1, test-ns2"
echo "Test pods: test-pod1 (test-ns1), test-pod2 (test-ns2)"
