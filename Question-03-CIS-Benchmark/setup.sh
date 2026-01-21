#!/bin/bash
# Setup for Question 03 - CIS Benchmark

set -e

echo "Installing kube-bench on nodes..."

# Install kube-bench on control plane (cplane-01)
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null cplane-01 'bash -s' << 'ENDSSH'
set -e

if ! command -v kube-bench &> /dev/null || [ ! -d /etc/kube-bench/cfg ]; then
    echo "Installing kube-bench on cplane-01..."
    cd /tmp
    curl -L https://github.com/aquasecurity/kube-bench/releases/download/v0.7.1/kube-bench_0.7.1_linux_amd64.tar.gz -o kube-bench.tar.gz
    tar -xzf kube-bench.tar.gz
    sudo mv kube-bench /usr/local/bin/
    sudo chmod +x /usr/local/bin/kube-bench

    # Install config files (required for kube-bench to work)
    sudo mkdir -p /etc/kube-bench
    sudo cp -r cfg /etc/kube-bench/

    # Clean up
    rm -rf /tmp/kube-bench.tar.gz /tmp/cfg
    echo "✓ kube-bench installed on cplane-01"
else
    echo "kube-bench already installed on cplane-01"
fi
ENDSSH

# Install kube-bench on worker node (node-01)
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null node-01 'bash -s' << 'ENDSSH'
set -e

if ! command -v kube-bench &> /dev/null || [ ! -d /etc/kube-bench/cfg ]; then
    echo "Installing kube-bench on node-01..."
    cd /tmp
    curl -L https://github.com/aquasecurity/kube-bench/releases/download/v0.7.1/kube-bench_0.7.1_linux_amd64.tar.gz -o kube-bench.tar.gz
    tar -xzf kube-bench.tar.gz
    sudo mv kube-bench /usr/local/bin/
    sudo chmod +x /usr/local/bin/kube-bench

    # Install config files (required for kube-bench to work)
    sudo mkdir -p /etc/kube-bench
    sudo cp -r cfg /etc/kube-bench/

    # Clean up
    rm -rf /tmp/kube-bench.tar.gz /tmp/cfg
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
echo "  On cplane-01: ssh cplane-01 'kube-bench run --targets=master --config-dir /etc/kube-bench/cfg'"
echo "  On node-01:   ssh node-01 'kube-bench run --targets=node --config-dir /etc/kube-bench/cfg'"
