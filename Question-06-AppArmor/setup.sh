#!/bin/bash
# Setup for Question 06 - AppArmor

set -e

# Create namespace
kubectl create namespace apparmor-ns --dry-run=client -o yaml | kubectl apply -f -

# Create output directory
mkdir -p /opt/course/06

echo "Environment ready!"
echo "Namespace: apparmor-ns"
echo ""
echo "Note: In a real environment, the AppArmor profile would be loaded with:"
echo "  sudo apparmor_parser -q /etc/apparmor.d/k8s-deny-write"
echo ""
echo "To check loaded profiles:"
echo "  sudo aa-status"
