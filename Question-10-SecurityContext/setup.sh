#!/bin/bash
# Setup for Question 10 - SecurityContext

set -e

# Create namespace
kubectl create namespace hardened-ns --dry-run=client -o yaml | kubectl apply -f -

# Create output directory
mkdir -p /opt/course/10

echo "Environment ready!"
echo "Namespace: hardened-ns"
