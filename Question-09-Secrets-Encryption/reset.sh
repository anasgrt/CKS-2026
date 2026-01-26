#!/bin/bash
# Reset Question 09 - Secrets Encryption

# Use timeout for kubectl commands since API server might be down
# These are best-effort cleanup - if API server is down, we'll fix it below
timeout 10 kubectl delete secret test-secret -n secrets-ns --ignore-not-found 2>/dev/null || true
timeout 10 kubectl delete namespace secrets-ns --ignore-not-found 2>/dev/null || true
rm -rf /opt/course/09

# Function to revert API server encryption config
revert_apiserver_encryption() {
    local MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
    # Store backup OUTSIDE manifests directory to avoid kubelet interference
    local BACKUP="/tmp/kube-apiserver.yaml.backup-encryption"

    # Check if any encryption config is present in the manifest (flag, volume, or volumeMount)
    if ! grep -q -E "encryption-provider-config|name: encryption-config" "$MANIFEST" 2>/dev/null; then
        echo "No encryption config found in API server manifest, skipping revert."
        # Still clean up any leftover backup files in manifests directory
        sudo rm -f /etc/kubernetes/manifests/kube-apiserver.yaml.backup-encryption 2>/dev/null
        return 0
    fi

    echo "Reverting API server encryption configuration..."

    # Create backup in /tmp (NOT in manifests directory)
    sudo cp "$MANIFEST" "$BACKUP"

    # Check if yq is available
    if command -v yq &>/dev/null; then
        echo "Using yq to remove encryption config..."

        # Remove the --encryption-provider-config flag (handle any path)
        sudo yq -i 'del(.spec.containers[0].command[] | select(. == "--encryption-provider-config=*"))' "$MANIFEST"
        sudo yq -i 'del(.spec.containers[0].command[] | select(test("--encryption-provider-config")))' "$MANIFEST"

        # Remove the encryption-config volumeMount
        sudo yq -i 'del(.spec.containers[0].volumeMounts[] | select(.name == "encryption-config"))' "$MANIFEST"

        # Remove the encryption-config volume
        sudo yq -i 'del(.spec.volumes[] | select(.name == "encryption-config"))' "$MANIFEST"
    else
        echo "Using Python to remove encryption config..."

        # Use Python for safe YAML manipulation (available on most systems)
        sudo python3 << 'PYTHON_SCRIPT'
import yaml
import sys

manifest_path = "/etc/kubernetes/manifests/kube-apiserver.yaml"

with open(manifest_path, 'r') as f:
    manifest = yaml.safe_load(f)

modified = False

# Remove --encryption-provider-config flag from command
if 'spec' in manifest and 'containers' in manifest['spec']:
    for container in manifest['spec']['containers']:
        if 'command' in container:
            original_len = len(container['command'])
            container['command'] = [
                cmd for cmd in container['command']
                if not cmd.startswith('--encryption-provider-config')
            ]
            if len(container['command']) < original_len:
                modified = True

        # Remove encryption-config volumeMount
        if 'volumeMounts' in container:
            original_len = len(container['volumeMounts'])
            container['volumeMounts'] = [
                vm for vm in container['volumeMounts']
                if vm.get('name') != 'encryption-config'
            ]
            if len(container['volumeMounts']) < original_len:
                modified = True

# Remove encryption-config volume
if 'spec' in manifest and 'volumes' in manifest['spec']:
    original_len = len(manifest['spec']['volumes'])
    manifest['spec']['volumes'] = [
        v for v in manifest['spec']['volumes']
        if v.get('name') != 'encryption-config'
    ]
    if len(manifest['spec']['volumes']) < original_len:
        modified = True

if modified:
    with open(manifest_path, 'w') as f:
        yaml.dump(manifest, f, default_flow_style=False, sort_keys=False)
    print("Manifest updated successfully")
else:
    print("No encryption config found to remove")
PYTHON_SCRIPT
    fi

    # Remove the encryption config file
    sudo rm -f /etc/kubernetes/encryption-config.yaml

    # Clean up any leftover backup files in manifests directory
    sudo rm -f /etc/kubernetes/manifests/kube-apiserver.yaml.backup-encryption 2>/dev/null

    echo "API server manifest updated."

    # CRITICAL: Force kubelet to recreate the pod sandbox with new configuration
    # The old pod sandbox caches the command args, so we must remove it completely
    echo "Forcing API server pod recreation to apply new configuration..."

    # Stop kubelet to prevent it from fighting us
    sudo systemctl stop kubelet

    # Find and remove all apiserver pod sandboxes
    # Using grep to reliably find the pod, then extract just the ID
    for POD_ID in $(crictl pods 2>/dev/null | grep kube-apiserver | awk '{print $1}'); do
        echo "Removing old API server pod sandbox ($POD_ID)..."
        crictl stopp "$POD_ID" 2>/dev/null || true
        crictl rmp "$POD_ID" 2>/dev/null || true
    done

    # Start kubelet to create fresh pod from updated manifest
    sudo systemctl start kubelet

    echo "Waiting for API server to come back online with new configuration..."
    local max_wait=90
    local waited=0
    while ! timeout 5 kubectl get nodes &>/dev/null && [ $waited -lt $max_wait ]; do
        echo "Waiting for API server... (${waited}s)"
        sleep 3
        waited=$((waited + 5))
    done

    if timeout 5 kubectl get nodes &>/dev/null; then
        echo "API server is back online."
        sudo rm -f "$BACKUP"
    else
        echo "WARNING: API server did not come back online within ${max_wait}s."
        echo "Backup saved at: $BACKUP"
        echo "You may need to manually check: crictl logs \$(crictl ps -a | grep apiserver | head -1 | awk '{print \$1}')"
    fi
}

# Clean up encryption config files on control plane (if accessible)
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 controlplane 'test -f /etc/kubernetes/manifests/kube-apiserver.yaml' 2>/dev/null; then
    echo "Cleaning up encryption config on controlplane..."

    # Run the revert function on controlplane via SSH
    ssh controlplane "$(declare -f revert_apiserver_encryption); revert_apiserver_encryption" 2>/dev/null || true

    # Also clean up any encryption config directories and leftover backup files
    ssh controlplane 'sudo rm -rf /etc/kubernetes/enc' 2>/dev/null || true
    ssh controlplane 'sudo rm -f /etc/kubernetes/manifests/kube-apiserver.yaml.backup-encryption' 2>/dev/null || true
else
    # Try locally if not using SSH (single-node cluster)
    if [ -f /etc/kubernetes/manifests/kube-apiserver.yaml ]; then
        revert_apiserver_encryption
        sudo rm -rf /etc/kubernetes/enc 2>/dev/null || true
        # Clean up any leftover backup files in manifests directory
        sudo rm -f /etc/kubernetes/manifests/kube-apiserver.yaml.backup-encryption 2>/dev/null || true
    fi
fi

echo ""
echo "Question 09 reset complete!"
