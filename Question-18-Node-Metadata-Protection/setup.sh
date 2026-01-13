#!/bin/bash
# Setup for Question 18 - Node Metadata Protection

set -e

# Create namespace
kubectl create namespace protected-ns --dry-run=client -o yaml | kubectl apply -f -

# Create output directory
mkdir -p /opt/course/18

echo "Environment ready!"
echo "Namespace: protected-ns"
echo ""
echo "Cloud metadata endpoints:"
echo "  AWS/GCP/Azure: 169.254.169.254"
echo "  AWS IMDSv2: 169.254.169.254 (requires token)"
echo "  GKE: metadata.google.internal (also 169.254.169.254)"
echo ""
echo "Test metadata access:"
echo "  curl -s http://169.254.169.254/latest/meta-data/"
