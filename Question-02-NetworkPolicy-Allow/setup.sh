#!/bin/bash
# Setup for Question 02 - NetworkPolicy Allow Specific Traffic

set -e

# Create namespaces
kubectl create namespace microservices-ns --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring-ns --dry-run=client -o yaml | kubectl apply -f -

# Create test pods with labels
kubectl run frontend --image=nginx --namespace=microservices-ns --labels=tier=frontend --restart=Never --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
kubectl run api --image=nginx --namespace=microservices-ns --labels=tier=api --restart=Never --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
kubectl run database --image=postgres --namespace=microservices-ns --labels=tier=database --restart=Never --env=POSTGRES_PASSWORD=secret --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# Create output directory
mkdir -p /opt/course/02

echo "Environment ready!"
echo "Namespace: microservices-ns, monitoring-ns"
echo "Test pods: frontend (tier=frontend), api (tier=api), database (tier=database)"
