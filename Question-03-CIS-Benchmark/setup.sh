#!/bin/bash
# Setup for Question 03 - CIS Benchmark

set -e

echo "Installing kube-bench on nodes..."

# Install kube-bench on control plane (key-ctrl)
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR key-ctrl 'bash -s' << 'ENDSSH'
set -e

# Check if kube-bench works (not just exists) - handles wrong architecture
if ! kube-bench version &> /dev/null || [ ! -d /etc/kube-bench/cfg ]; then
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

# Check if kube-bench works (not just exists) - handles wrong architecture
if ! kube-bench version &> /dev/null || [ ! -d /etc/kube-bench/cfg ]; then
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

echo ""
echo "Introducing security misconfigurations for the exercise..."

# Introduce security misconfigurations on control plane for user to fix
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR key-ctrl 'bash -s' << 'ENDSSH'
set -e

API_SERVER_MANIFEST="/var/lib/rancher/rke2/agent/pod-manifests/kube-apiserver.yaml"

# Backup original manifest
sudo cp "$API_SERVER_MANIFEST" "${API_SERVER_MANIFEST}.backup"

# Introduce misconfigurations:
# 1. Enable anonymous auth (insecure)
sudo sed -i 's/--anonymous-auth=false/--anonymous-auth=true/' "$API_SERVER_MANIFEST"

# 2. Enable profiling (security risk)
sudo sed -i 's/--profiling=false/--profiling=true/' "$API_SERVER_MANIFEST"

# 3. Remove Node from authorization-mode (weaker authorization)
sudo sed -i 's/--authorization-mode=Node,RBAC/--authorization-mode=RBAC/' "$API_SERVER_MANIFEST"

echo "✓ Security misconfigurations introduced on key-ctrl"
echo "  - anonymous-auth=true (should be false)"
echo "  - profiling=true (should be false)"
echo "  - authorization-mode=RBAC (should include Node)"

# Create output directory on control plane
sudo mkdir -p /opt/course/03
sudo chmod 777 /opt/course/03
ENDSSH

# Wait for API server to restart with new config
echo "Waiting for API server to restart..."
sleep 15

echo ""
echo "✓ Environment ready!"
echo ""
echo "Important paths:"
echo "  API Server manifest: /var/lib/rancher/rke2/agent/pod-manifests/kube-apiserver.yaml (on key-ctrl)"
echo "  Kubelet config: /etc/rancher/rke2/config.yaml (on key-worker)"
echo "  Output directory: /opt/course/03/ (on key-ctrl)"
echo ""
echo "Run kube-bench:"
echo "  On key-ctrl:   ssh key-ctrl 'kube-bench run --targets=master --config-dir /etc/kube-bench/cfg'"
echo "  On key-worker: ssh key-worker 'kube-bench run --targets=node --config-dir /etc/kube-bench/cfg'"
