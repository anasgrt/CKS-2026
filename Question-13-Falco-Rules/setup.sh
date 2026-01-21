#!/bin/bash
# Setup for Question 13 - Falco Rules

set -e

echo "Setting up Falco on node-01..."

# Install Falco on node-01
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null node-01 'bash -s' << 'ENDSSH'
set -e

# Check if Falco is already installed
if ! command -v falco &> /dev/null; then
    echo "Installing Falco..."

    # Install required dependencies
    sudo apt-get update -qq
    sudo apt-get install -y -qq curl gnupg

    # Add Falco repository
    curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | \
      sudo gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg

    sudo cat > /etc/apt/sources.list.d/falcosecurity.list << 'EOF'
deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main
EOF

    # Install Falco
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq linux-headers-$(uname -r) falco

    # Create rules directory if it doesn't exist
    sudo mkdir -p /etc/falco/rules.d

    # Enable and start Falco service
    sudo systemctl enable falco
    sudo systemctl start falco

    # Wait for service to start
    sleep 3

    echo "✓ Falco installed successfully"
else
    echo "Falco already installed"
    # Ensure it's running
    sudo systemctl start falco 2>/dev/null || true
fi

# Verify Falco is running
if sudo systemctl is-active --quiet falco; then
    echo "✓ Falco service is running"
else
    echo "✗ Falco service failed to start"
    sudo journalctl -u falco -n 20 --no-pager
    exit 1
fi
ENDSSH

# Create namespace
kubectl create namespace falco-ns --dry-run=client -o yaml | kubectl apply -f -

# Create test pod
kubectl run test-pod --image=nginx --namespace=falco-ns --restart=Never --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# Create output directory
mkdir -p /opt/course/13

echo ""
echo "✓ Environment ready!"
echo "  Namespace: falco-ns"
echo "  Test pod: test-pod"
echo "  Falco running on node-01"
echo ""
echo "Check Falco logs with:"
echo "  ssh node-01 'sudo journalctl -u falco -f'"
echo "  ssh node-01 'sudo journalctl -u falco | tail -20'"
