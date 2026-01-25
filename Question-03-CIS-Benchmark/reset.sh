#!/bin/bash
# Reset Question 03 - CIS Benchmark

echo "Restoring original API server configuration on key-ctrl..."

# Restore original API server manifest from backup and clean up directory
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR key-ctrl 'bash -s' << 'ENDSSH'
set -e

API_SERVER_MANIFEST="/var/lib/rancher/rke2/agent/pod-manifests/kube-apiserver.yaml"
BACKUP_FILE="${API_SERVER_MANIFEST}.backup"

if [ -f "$BACKUP_FILE" ]; then
    sudo cp "$BACKUP_FILE" "$API_SERVER_MANIFEST"
    sudo rm -f "$BACKUP_FILE"
    echo "✓ API server manifest restored from backup"
else
    echo "No backup found. Manually restoring secure settings..."
    # Ensure secure settings are in place
    sudo sed -i 's/--anonymous-auth=true/--anonymous-auth=false/' "$API_SERVER_MANIFEST"
    sudo sed -i 's/--profiling=true/--profiling=false/' "$API_SERVER_MANIFEST"
    sudo sed -i 's/--authorization-mode=RBAC$/--authorization-mode=Node,RBAC/' "$API_SERVER_MANIFEST"
    echo "✓ Security settings restored manually"
fi

# Clean up output directory on control plane
sudo rm -rf /opt/course/03
ENDSSH

# Wait for API server to restart with restored config
echo "Waiting for API server to restart..."
sleep 15

echo ""
echo "Question 03 reset complete!"
echo ""
echo "Note: kube-bench tool is kept installed on nodes as infrastructure."
