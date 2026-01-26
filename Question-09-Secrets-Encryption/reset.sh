#!/bin/bash
# Reset Question 09 - Secrets Encryption

kubectl delete secret test-secret -n secrets-ns --ignore-not-found
kubectl delete namespace secrets-ns --ignore-not-found
rm -rf /opt/course/09

# Function to revert API server encryption config
revert_apiserver_encryption() {
    local MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
    local BACKUP="/etc/kubernetes/manifests/kube-apiserver.yaml.backup-encryption"

    # Check if any encryption config is present in the manifest (flag, volume, or volumeMount)
    if ! grep -q -E "encryption-provider-config|name: encryption-config" "$MANIFEST" 2>/dev/null; then
        echo "No encryption config found in API server manifest, skipping revert."
        return 0
    fi

    echo "Reverting API server encryption configuration..."

    # Create backup
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
        echo "Using sed/perl to remove encryption config..."

        # Remove the --encryption-provider-config flag line
        sudo sed -i '/--encryption-provider-config/d' "$MANIFEST"

        # Remove volumeMount block (format: mountPath, name, readOnly)
        sudo perl -i -0pe 's/\s*- mountPath: \/etc\/kubernetes\/encryption-config\.yaml\n\s*name: encryption-config\n\s*readOnly: true\n?//g' "$MANIFEST"

        # Remove volume block (format: hostPath with nested path, type, name)
        sudo perl -i -0pe 's/\s*- hostPath:\n\s*path: \/etc\/kubernetes\/encryption-config\.yaml\n\s*type: \w+\n\s*name: encryption-config\n?//g' "$MANIFEST"

        # Alternative volume format (name first)
        sudo perl -i -0pe 's/\s*- name: encryption-config\n\s*hostPath:\n\s*path: \/etc\/kubernetes\/encryption-config\.yaml\n\s*type: \w+\n?//g' "$MANIFEST"
    fi

    echo "API server manifest updated. Waiting for API server to restart..."

    # Remove the encryption config file
    sudo rm -f /etc/kubernetes/encryption-config.yaml

    # Wait for API server to restart (it auto-restarts when manifest changes)
    sleep 5
    local max_wait=60
    local waited=0
    while ! kubectl get nodes &>/dev/null && [ $waited -lt $max_wait ]; do
        echo "Waiting for API server to come back online... (${waited}s)"
        sleep 5
        waited=$((waited + 5))
    done

    if kubectl get nodes &>/dev/null; then
        echo "API server is back online."
        sudo rm -f "$BACKUP"
    else
        echo "WARNING: API server did not come back online within ${max_wait}s."
        echo "Backup saved at: $BACKUP"
        echo "You may need to manually fix the manifest."
    fi
}

# Clean up encryption config files on control plane (if accessible)
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 controlplane 'test -f /etc/kubernetes/manifests/kube-apiserver.yaml' 2>/dev/null; then
    echo "Cleaning up encryption config on controlplane..."

    # Run the revert function on controlplane via SSH
    ssh controlplane "$(declare -f revert_apiserver_encryption); revert_apiserver_encryption" 2>/dev/null || true

    # Also clean up any encryption config directories
    ssh controlplane 'sudo rm -rf /etc/kubernetes/enc' 2>/dev/null || true
else
    # Try locally if not using SSH (single-node cluster)
    if [ -f /etc/kubernetes/manifests/kube-apiserver.yaml ]; then
        revert_apiserver_encryption
        sudo rm -rf /etc/kubernetes/enc 2>/dev/null || true
    fi
fi

echo ""
echo "Question 09 reset complete!"
