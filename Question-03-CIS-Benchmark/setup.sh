#!/bin/bash
# Setup for Question 03 - CIS Benchmark

set -e

echo "Installing kube-bench on nodes..."

# Install kube-bench on control plane (cplane-01)
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null cplane-01 'bash -s' << 'ENDSSH'
set -e

if ! command -v kube-bench &> /dev/null; then
    echo "Installing kube-bench on cplane-01..."
    curl -L https://github.com/aquasecurity/kube-bench/releases/download/v0.7.1/kube-bench_0.7.1_linux_amd64.tar.gz -o /tmp/kube-bench.tar.gz
    tar -xzf /tmp/kube-bench.tar.gz -C /tmp
    sudo mv /tmp/kube-bench /usr/local/bin/
    sudo chmod +x /usr/local/bin/kube-bench
    rm /tmp/kube-bench.tar.gz
    echo "✓ kube-bench installed on cplane-01"
else
    echo "kube-bench already installed on cplane-01"
fi
ENDSSH

# Install kube-bench on worker node (node-01)
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null node-01 'bash -s' << 'ENDSSH'
set -e

if ! command -v kube-bench &> /dev/null; then
    echo "Installing kube-bench on node-01..."
    curl -L https://github.com/aquasecurity/kube-bench/releases/download/v0.7.1/kube-bench_0.7.1_linux_amd64.tar.gz -o /tmp/kube-bench.tar.gz
    tar -xzf /tmp/kube-bench.tar.gz -C /tmp
    sudo mv /tmp/kube-bench /usr/local/bin/
    sudo chmod +x /usr/local/bin/kube-bench
    rm /tmp/kube-bench.tar.gz
    echo "✓ kube-bench installed on node-01"
else
    echo "kube-bench already installed on node-01"
fi
ENDSSH

# Create output directory
mkdir -p /opt/course/03

echo ""
echo "✓ Environment ready!"
echo ""
echo "Important paths:"
echo "  API Server manifest: /etc/kubernetes/manifests/kube-apiserver.yaml (on cplane-01)"
echo "  Output directory: /opt/course/03/"
echo ""
echo "Run kube-bench:"
echo "  On cplane-01: ssh cplane-01 'sudo kube-bench run --targets=master'"
echo "  On node-01:   ssh node-01 'sudo kube-bench run --targets=node'"
