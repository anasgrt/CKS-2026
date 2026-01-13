#!/bin/bash
# Setup for Question 13 - Falco Rules

set -e

# Create namespace
kubectl create namespace falco-ns --dry-run=client -o yaml | kubectl apply -f -

# Create test pod
kubectl run test-pod --image=nginx --namespace=falco-ns --restart=Never --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# Create output directory
mkdir -p /opt/course/13

echo "Environment ready!"
echo "Namespace: falco-ns"
echo "Test pod: test-pod"
echo ""
echo "Falco paths:"
echo "  Default rules: /etc/falco/falco_rules.yaml"
echo "  Local rules: /etc/falco/falco_rules.local.yaml"
echo "  Custom rules: /etc/falco/rules.d/"
echo ""
echo "Check Falco logs:"
echo "  journalctl -u falco -f"
echo "  OR: kubectl logs -n falco <falco-pod> -f"
