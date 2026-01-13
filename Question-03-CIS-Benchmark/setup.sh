#!/bin/bash
# Setup for Question 03 - CIS Benchmark

set -e

# Create output directory
mkdir -p /opt/course/03

echo "Environment ready!"
echo ""
echo "Important paths:"
echo "  API Server manifest: /etc/kubernetes/manifests/kube-apiserver.yaml"
echo "  Output directory: /opt/course/03/"
echo ""
echo "Run kube-bench with:"
echo "  kube-bench run --targets=master"
echo ""
echo "Note: You need to SSH to the control plane node to make changes."
