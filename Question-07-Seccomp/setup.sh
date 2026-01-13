#!/bin/bash
# Setup for Question 07 - Seccomp

set -e

# Create namespace
kubectl create namespace seccomp-ns --dry-run=client -o yaml | kubectl apply -f -

# Create output directory
mkdir -p /opt/course/07

echo "Environment ready!"
echo "Namespace: seccomp-ns"
echo ""
echo "Note: Custom seccomp profiles should be at /var/lib/kubelet/seccomp/"
echo "      The RuntimeDefault profile is built into the container runtime."
