#!/bin/bash
# Setup for Question 21 - Gatekeeper Image Registry Restriction
# Based on real CKS exam patterns (2025/2026)

set -e

echo "Setting up Gatekeeper Image Registry Restriction scenario..."

# Create output directory
mkdir -p /opt/course/21

# Check if Gatekeeper is already installed
if kubectl get ns gatekeeper-system &>/dev/null; then
    echo "Gatekeeper namespace already exists, checking pods..."
    kubectl get pods -n gatekeeper-system
else
    echo "Installing OPA Gatekeeper..."

    # Install Gatekeeper using the official manifest
    kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.14.0/deploy/gatekeeper.yaml

    echo "Waiting for Gatekeeper pods to be ready..."
    kubectl wait --for=condition=Ready pods --all -n gatekeeper-system --timeout=120s || true
fi

echo ""
echo "Gatekeeper installation status:"
kubectl get pods -n gatekeeper-system
echo ""

# Create a test namespace
kubectl create namespace gatekeeper-test --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "=============================================="
echo "Setup complete!"
echo "=============================================="
echo ""
echo "Gatekeeper is installed. Your task is to:"
echo ""
echo "1. Create a ConstraintTemplate 'k8sallowedrepos' that checks image registries"
echo "2. Create a Constraint 'allowed-repos' that allows only specific registries"
echo "3. Test with allowed and disallowed images"
echo ""
echo "Allowed registries should be:"
echo "  - docker.io/library/"
echo "  - gcr.io/google-containers/"
echo "  - registry.k8s.io/"
echo ""
echo "Save files to /opt/course/21/"
