#!/bin/bash
# Setup for Question 06 - AppArmor

set -e

echo "Setting up AppArmor on node-01..."

# Install AppArmor on node-01
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null node-01 'bash -s' << 'ENDSSH'
set -e

# Install AppArmor utilities if not already installed
if ! command -v aa-status &> /dev/null; then
    echo "Installing AppArmor..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq apparmor apparmor-utils
fi

# Check if AppArmor is enabled in kernel
if [ ! -d "/sys/kernel/security/apparmor" ]; then
    echo "⚠ AppArmor not enabled in kernel - checking boot parameters..."
    if ! grep -q "apparmor=1 security=apparmor" /proc/cmdline; then
        echo "AppArmor kernel parameters missing. Adding to GRUB configuration..."
        sudo sed -i 's/GRUB_CMDLINE_LINUX="[^"]*/& apparmor=1 security=apparmor/' /etc/default/grub 2>/dev/null || true
        echo "⚠ Node requires reboot for AppArmor to take effect"
        echo "Run: ssh node-01 'sudo reboot'"
        exit 1
    fi
fi

# Mount AppArmor securityfs if not mounted
if [ ! -d "/sys/kernel/security/apparmor" ]; then
    sudo mount -t securityfs securityfs /sys/kernel/security || true
fi

# Ensure AppArmor is running
sudo systemctl enable apparmor 2>/dev/null || true
sudo systemctl start apparmor 2>/dev/null || true

# Create the k8s-deny-write profile
sudo mkdir -p /etc/apparmor.d

sudo cat > /etc/apparmor.d/k8s-deny-write << 'EOF'
#include <tunables/global>

profile k8s-deny-write flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  # Allow network access
  network,

  # Allow reading most files
  / r,
  /** r,

  # Deny all write operations
  deny /** w,

  # Allow necessary capabilities
  capability setgid,
  capability setuid,
  capability dac_override,
  capability net_bind_service,
}
EOF

# Load the profile
sudo apparmor_parser -r /etc/apparmor.d/k8s-deny-write

# Verify the profile is loaded
if sudo aa-status | grep -q k8s-deny-write; then
    echo "✓ AppArmor profile 'k8s-deny-write' loaded successfully"
else
    echo "✗ Failed to load AppArmor profile"
    exit 1
fi
ENDSSH

# Create namespace
kubectl create namespace apparmor-ns --dry-run=client -o yaml | kubectl apply -f -

# Create output directory
mkdir -p /opt/course/06

echo ""
echo "✓ Environment ready!"
echo "  Namespace: apparmor-ns"
echo "  AppArmor profile 'k8s-deny-write' loaded on node-01"
echo ""
echo "Verify with: ssh node-01 'sudo aa-status | grep k8s-deny-write'"
