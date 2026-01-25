#!/bin/bash
# Setup for Question 03 - CIS Benchmark

set -e

echo "Installing kube-bench on nodes..."

# Install kube-bench on control plane (key-ctrl)
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR key-ctrl 'bash -s' << 'ENDSSH'
set -e

if ! command -v kube-bench &> /dev/null || [ ! -d /etc/kube-bench/cfg ]; then
    echo "Installing kube-bench on key-ctrl..."
    cd /tmp

    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        arm64)   ARCH="arm64" ;;
    esac

    curl -L "https://github.com/aquasecurity/kube-bench/releases/download/v0.8.0/kube-bench_0.8.0_linux_${ARCH}.tar.gz" -o kube-bench.tar.gz
    tar -xzf kube-bench.tar.gz
    sudo mv kube-bench /usr/local/bin/
    sudo chmod +x /usr/local/bin/kube-bench

    # Install config files (required for kube-bench to work)
    sudo mkdir -p /etc/kube-bench
    sudo cp -r cfg /etc/kube-bench/

    # Clean up
    rm -rf /tmp/kube-bench.tar.gz /tmp/cfg
    echo "✓ kube-bench installed on key-ctrl"
else
    echo "kube-bench already installed on key-ctrl"
fi
ENDSSH

# Install kube-bench on worker node (key-worker)
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR key-worker 'bash -s' << 'ENDSSH'
set -e

if ! command -v kube-bench &> /dev/null || [ ! -d /etc/kube-bench/cfg ]; then
    echo "Installing kube-bench on key-worker..."
    cd /tmp

    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        arm64)   ARCH="arm64" ;;
    esac

    curl -L "https://github.com/aquasecurity/kube-bench/releases/download/v0.8.0/kube-bench_0.8.0_linux_${ARCH}.tar.gz" -o kube-bench.tar.gz
    tar -xzf kube-bench.tar.gz
    sudo mv kube-bench /usr/local/bin/
    sudo chmod +x /usr/local/bin/kube-bench

    # Install config files (required for kube-bench to work)
    sudo mkdir -p /etc/kube-bench
    sudo cp -r cfg /etc/kube-bench/

    # Clean up
    rm -rf /tmp/kube-bench.tar.gz /tmp/cfg
    echo "✓ kube-bench installed on key-worker"
else
    echo "kube-bench already installed on key-worker"
fi
ENDSSH

# Create output directory
mkdir -p /opt/course/03

echo ""
echo "✓ Environment ready!"
echo ""
echo "Important paths:"
echo "  API Server manifest: /etc/kubernetes/manifests/kube-apiserver.yaml (on key-ctrl)"
echo "  Output directory: /opt/course/03/"
echo ""
echo "Run kube-bench:"
echo "  On key-ctrl:   ssh key-ctrl 'kube-bench run --targets=master --config-dir /etc/kube-bench/cfg'"
echo "  On key-worker: ssh key-worker 'kube-bench run --targets=node --config-dir /etc/kube-bench/cfg'"
