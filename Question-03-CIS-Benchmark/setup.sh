#!/bin/bash
# Setup for Question 03 - CIS Benchmark

set -e

echo "Installing kube-bench on nodes..."

# Install kube-bench on control plane (controlplane)
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR controlplane 'bash -s' << 'ENDSSH'
set -e

# Check if kube-bench works (not just exists) - handles wrong architecture
if ! kube-bench version &> /dev/null || [ ! -d /etc/kube-bench/cfg ]; then
    echo "Installing kube-bench on controlplane..."
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
    echo "✓ kube-bench installed on controlplane"
else
    echo "kube-bench already installed on controlplane"
fi
ENDSSH

# Install kube-bench on worker node (node01)
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR node01 'bash -s' << 'ENDSSH'
set -e

# Check if kube-bench works (not just exists) - handles wrong architecture
if ! kube-bench version &> /dev/null || [ ! -d /etc/kube-bench/cfg ]; then
    echo "Installing kube-bench on node01..."
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
    echo "✓ kube-bench installed on node01"
else
    echo "kube-bench already installed on node01"
fi
ENDSSH

echo ""
echo "Introducing security misconfigurations for the exercise..."

# Introduce security misconfigurations on control plane for user to fix
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR controlplane 'bash -s' << 'ENDSSH'
set -e

API_SERVER_MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"

# Backup original manifest
sudo cp "$API_SERVER_MANIFEST" "${API_SERVER_MANIFEST}.backup"

# Introduce misconfigurations:
# 1. Enable anonymous auth (insecure)
sudo sed -i 's/--anonymous-auth=false/--anonymous-auth=true/' "$API_SERVER_MANIFEST"

# 2. Enable profiling (security risk) - add if not present or change to true
if grep -q "\-\-profiling=" "$API_SERVER_MANIFEST"; then
    sudo sed -i 's/--profiling=false/--profiling=true/' "$API_SERVER_MANIFEST"
else
    sudo sed -i '/--anonymous-auth/a\    - --profiling=true' "$API_SERVER_MANIFEST"
fi

# 3. Remove Node from authorization-mode (weaker authorization)
sudo sed -i 's/--authorization-mode=Node,RBAC/--authorization-mode=RBAC/' "$API_SERVER_MANIFEST"

echo "✓ Security misconfigurations introduced on controlplane"
echo "  - anonymous-auth=true (should be false)"
echo "  - profiling=true (should be false)"
echo "  - authorization-mode=RBAC (should include Node)"

# Create output directory on control plane
sudo mkdir -p /opt/course/03
sudo chmod 777 /opt/course/03
ENDSSH

# Wait for API server to restart with new config
echo "Waiting for API server to restart..."
sleep 20

# Introduce worker node misconfiguration for CIS 4.2.6
echo ""
echo "Introducing kubelet misconfiguration on worker node..."

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR node01 'bash -s' << 'ENDSSH'
set -e

KUBELET_CONFIG="/var/lib/kubelet/config.yaml"

# Backup kubelet config
sudo cp "$KUBELET_CONFIG" "${KUBELET_CONFIG}.backup"

# Ensure protectKernelDefaults is false or removed (causes CIS 4.2.6 to fail)
if grep -q "protectKernelDefaults:" "$KUBELET_CONFIG"; then
    sudo sed -i 's/protectKernelDefaults: true/protectKernelDefaults: false/' "$KUBELET_CONFIG"
fi

# Restart kubelet to apply changes
sudo systemctl restart kubelet

echo "✓ Kubelet misconfiguration introduced on node01"
echo "  - protectKernelDefaults not set to true (CIS 4.2.6)"
ENDSSH

echo ""
echo "✓ Environment ready!"
echo ""
echo "Important paths:"
echo "  API Server manifest: /etc/kubernetes/manifests/kube-apiserver.yaml (on controlplane)"
echo "  Kubelet config: /var/lib/kubelet/config.yaml (on node01)"
echo "  Output directory: /opt/course/03/ (on controlplane)"
echo ""
echo "Run kube-bench:"
echo "  On controlplane: kube-bench run --targets=master"
echo "  On node01:       ssh node01 'kube-bench run --targets=node'"
