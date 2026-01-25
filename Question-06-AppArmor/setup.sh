#!/bin/bash
# Setup for Question 06 - AppArmor

set -e

echo "Setting up Question-06-AppArmor..."
echo ""

# Function to wait for node to be ready
wait_for_node() {
    local node=$1
    local max_attempts=60
    local attempt=0

    echo "Waiting for $node to come back online..."
    while [ $attempt -lt $max_attempts ]; do
        if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 "$node" 'echo ready' 2>/dev/null | grep -q ready; then
            echo "✓ $node is back online"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    echo "✗ Timeout waiting for $node"
    return 1
}

# Function to check if AppArmor is fully functional
check_apparmor_functional() {
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR node01 \
        'sudo aa-status &>/dev/null && [ -d "/sys/kernel/security/apparmor" ]' 2>/dev/null
}

echo "Setting up AppArmor on node01..."

# First pass: Install and configure AppArmor
NEEDS_REBOOT=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR node01 'bash -s' 2>/dev/null << 'ENDSSH'
set -e

# Install AppArmor utilities if not already installed
if ! command -v aa-status &> /dev/null; then
    echo "Installing AppArmor..." >&2
    sudo apt-get update -qq
    sudo apt-get install -y -qq apparmor apparmor-utils
fi

# Try to mount securityfs if not mounted
if [ ! -d "/sys/kernel/security/apparmor" ]; then
    sudo mount -t securityfs securityfs /sys/kernel/security 2>/dev/null || true
fi

# Ensure AppArmor service is running
sudo systemctl enable apparmor 2>/dev/null || true
sudo systemctl start apparmor 2>/dev/null || true

# Check if AppArmor is now functional
if [ -d "/sys/kernel/security/apparmor" ] && sudo aa-status &>/dev/null; then
    echo "NO_REBOOT"
    exit 0
fi

# AppArmor not functional - check if kernel parameters are set
if ! grep -q "apparmor=1" /proc/cmdline; then
    echo "Adding AppArmor kernel parameters to GRUB..." >&2
    sudo sed -i 's/GRUB_CMDLINE_LINUX="[^"]*/& apparmor=1 security=apparmor/' /etc/default/grub 2>/dev/null || true
    sudo update-grub 2>/dev/null || true
fi

echo "NEEDS_REBOOT"
ENDSSH
)

# Trim whitespace and check if reboot is needed
NEEDS_REBOOT=$(echo "$NEEDS_REBOOT" | tr -d '[:space:]')

if [ "$NEEDS_REBOOT" = "NEEDS_REBOOT" ]; then
    echo ""
    echo "AppArmor requires a node reboot to enable kernel support..."
    echo "Rebooting node01..."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR node01 'sudo reboot' 2>/dev/null || true

    # Wait a moment for the reboot to initiate
    sleep 5

    # Wait for node to come back
    if ! wait_for_node node01; then
        echo "✗ Failed to reboot node01. Please reboot manually and re-run setup."
        exit 1
    fi

    # Wait for Kubernetes node to be Ready
    echo "Waiting for node01 to be Ready in Kubernetes..."
    k8s_attempts=0
    while [ $k8s_attempts -lt 30 ]; do
        if kubectl get node node01 2>/dev/null | grep -q " Ready"; then
            echo "✓ node01 is Ready in Kubernetes"
            break
        fi
        k8s_attempts=$((k8s_attempts + 1))
        sleep 5
    done
fi

# Verify AppArmor is functional after potential reboot
if ! check_apparmor_functional; then
    echo "✗ AppArmor still not functional after setup. Manual intervention may be required."
    exit 1
fi

echo "✓ AppArmor kernel support is active"

# Second pass: Create the profile file but DO NOT load it
# User must load it as part of the exercise
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR node01 'bash -s' << 'ENDSSH'
set -e

# Ensure AppArmor is running
sudo systemctl enable apparmor 2>/dev/null || true
sudo systemctl start apparmor 2>/dev/null || true

# Create the k8s-deny-write profile file (but DO NOT load it)
sudo mkdir -p /etc/apparmor.d

sudo tee /etc/apparmor.d/k8s-deny-write > /dev/null << 'EOF'
#include <tunables/global>

profile k8s-deny-write flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  # Allow network access
  network,

  # Allow reading and executing files
  file,

  # Deny file write operations (but allow /dev, /proc, /sys writes)
  deny /bin/** w,
  deny /boot/** w,
  deny /etc/** w,
  deny /home/** w,
  deny /lib/** w,
  deny /lib64/** w,
  deny /media/** w,
  deny /mnt/** w,
  deny /opt/** w,
  deny /root/** w,
  deny /sbin/** w,
  deny /srv/** w,
  deny /tmp/** w,
  deny /usr/** w,
  deny /var/** w,

  # Allow necessary capabilities
  capability,
}
EOF

echo "✓ AppArmor profile file created at /etc/apparmor.d/k8s-deny-write"
echo "  NOTE: Profile is NOT loaded. User must load it with:"
echo "        sudo apparmor_parser -r /etc/apparmor.d/k8s-deny-write"
ENDSSH

# Create namespace
kubectl create namespace apparmor-ns --dry-run=client -o yaml | kubectl apply -f -

# Create output directory
mkdir -p /opt/course/06

echo ""
echo "✓ Environment ready!"
echo "  Namespace: apparmor-ns"
echo "  AppArmor profile FILE created at /etc/apparmor.d/k8s-deny-write on node01"
echo "  NOTE: Profile is NOT loaded yet - this is part of the exercise!"
echo ""
echo "Verify profile file exists: ssh node01 'ls -la /etc/apparmor.d/k8s-deny-write'"
echo "Check if profile is loaded: ssh node01 'sudo aa-status | grep k8s-deny-write'"
