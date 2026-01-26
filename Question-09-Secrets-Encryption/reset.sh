#!/bin/bash
# Reset Question 09 - Secrets Encryption

# CRITICAL FIX: Before removing encryption config, we MUST re-encrypt all secrets
# back to plaintext (identity provider). Otherwise, etcd will have encrypted data
# that the API server can no longer decrypt, causing namespace deletion to hang.

set -e

echo "=== Question 09 Reset - Secrets Encryption ==="

# Function to wait for API server
wait_for_apiserver() {
    local max_wait=${1:-120}
    local waited=0
    echo "Waiting for API server to come back online..."
    while ! timeout 5 kubectl get nodes &>/dev/null && [ $waited -lt $max_wait ]; do
        echo "  Waiting for API server... (${waited}s)"
        sleep 5
        waited=$((waited + 5))
    done

    if timeout 5 kubectl get nodes &>/dev/null; then
        echo "  API server is online."
        return 0
    else
        echo "  WARNING: API server did not come back online within ${max_wait}s."
        return 1
    fi
}

# Function to restart API server (for encryption config changes)
restart_apiserver() {
    echo "Restarting API server to apply configuration changes..."

    # Stop kubelet to prevent it from fighting us
    sudo systemctl stop kubelet

    # Find and remove all apiserver pod sandboxes
    for POD_ID in $(crictl pods 2>/dev/null | grep kube-apiserver | awk '{print $1}'); do
        echo "  Removing old API server pod sandbox ($POD_ID)..."
        crictl stopp "$POD_ID" 2>/dev/null || true
        crictl rmp "$POD_ID" 2>/dev/null || true
    done

    # Start kubelet to create fresh pod from updated manifest
    sudo systemctl start kubelet

    wait_for_apiserver 120
}

# Function to re-encrypt all secrets to use identity (plaintext) provider
decrypt_all_secrets() {
    local ENCRYPTION_CONFIG="/etc/kubernetes/encryption-config.yaml"

    if [ ! -f "$ENCRYPTION_CONFIG" ]; then
        echo "No encryption config found, skipping secret decryption."
        return 0
    fi

    echo "=== Step 1: Re-encrypting secrets to plaintext before removing encryption ==="

    # Save original encryption config
    sudo cp "$ENCRYPTION_CONFIG" /tmp/encryption-config-original.yaml

    # Get the existing key from the config (we need it to decrypt existing secrets)
    local existing_key=$(grep -A5 "aescbc:" "$ENCRYPTION_CONFIG" 2>/dev/null | grep "secret:" | head -1 | awk '{print $2}')

    if [ -z "$existing_key" ]; then
        echo "  No aescbc key found in config, secrets may already be plaintext."
        return 0
    fi

    echo "  Found existing encryption key, creating decryption config..."

    # Create a NEW encryption config with identity FIRST (for writing plaintext)
    # but keep the old key SECOND (for reading encrypted secrets)
    sudo tee "$ENCRYPTION_CONFIG" > /dev/null << EOF
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - identity: {}
  - aescbc:
      keys:
      - name: key1
        secret: ${existing_key}
EOF

    echo "  Restarting API server with identity-first config..."
    restart_apiserver

    if ! timeout 5 kubectl get nodes &>/dev/null; then
        echo "  ERROR: API server failed to start. Restoring original config."
        sudo cp /tmp/encryption-config-original.yaml "$ENCRYPTION_CONFIG"
        restart_apiserver
        return 1
    fi

    echo "  Re-writing all secrets to use plaintext storage..."

    # Re-write all secrets in all namespaces to store them as plaintext
    # This reads with old key (aescbc) and writes with new first provider (identity)
    local namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

    for ns in $namespaces; do
        local secrets=$(kubectl get secrets -n "$ns" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
        for secret in $secrets; do
            # Skip service account tokens (they're managed by the system)
            if [[ "$secret" == *-token-* ]] || [[ "$secret" == "default-token"* ]]; then
                continue
            fi
            echo "    Re-encrypting: $ns/$secret"
            kubectl get secret "$secret" -n "$ns" -o json 2>/dev/null | kubectl replace -f - 2>/dev/null || true
        done
    done

    echo "  All secrets have been re-encrypted to plaintext."
    sudo rm -f /tmp/encryption-config-original.yaml
}

# Function to completely remove encryption configuration
remove_encryption_config() {
    local MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
    local ENCRYPTION_CONFIG="/etc/kubernetes/encryption-config.yaml"

    if ! grep -q -E "encryption-provider-config|name: encryption-config" "$MANIFEST" 2>/dev/null; then
        echo "No encryption config found in API server manifest, skipping removal."
        sudo rm -f "$ENCRYPTION_CONFIG" 2>/dev/null
        return 0
    fi

    echo "=== Step 2: Removing encryption configuration from API server ==="

    # Create backup
    sudo cp "$MANIFEST" /tmp/kube-apiserver.yaml.backup-encryption

    if command -v yq &>/dev/null; then
        echo "  Using yq to remove encryption config..."
        sudo yq -i 'del(.spec.containers[0].command[] | select(test("--encryption-provider-config")))' "$MANIFEST"
        sudo yq -i 'del(.spec.containers[0].volumeMounts[] | select(.name == "encryption-config"))' "$MANIFEST"
        sudo yq -i 'del(.spec.volumes[] | select(.name == "encryption-config"))' "$MANIFEST"
    else
        echo "  Using Python to remove encryption config..."
        sudo python3 << 'PYTHON_SCRIPT'
import yaml

manifest_path = "/etc/kubernetes/manifests/kube-apiserver.yaml"

with open(manifest_path, 'r') as f:
    manifest = yaml.safe_load(f)

# Remove --encryption-provider-config flag from command
if 'spec' in manifest and 'containers' in manifest['spec']:
    for container in manifest['spec']['containers']:
        if 'command' in container:
            container['command'] = [
                cmd for cmd in container['command']
                if not cmd.startswith('--encryption-provider-config')
            ]
        if 'volumeMounts' in container:
            container['volumeMounts'] = [
                vm for vm in container['volumeMounts']
                if vm.get('name') != 'encryption-config'
            ]

if 'spec' in manifest and 'volumes' in manifest['spec']:
    manifest['spec']['volumes'] = [
        v for v in manifest['spec']['volumes']
        if v.get('name') != 'encryption-config'
    ]

with open(manifest_path, 'w') as f:
    yaml.dump(manifest, f, default_flow_style=False, sort_keys=False)
print("Manifest updated successfully")
PYTHON_SCRIPT
    fi

    # Remove the encryption config file
    sudo rm -f "$ENCRYPTION_CONFIG"

    echo "  Restarting API server without encryption..."
    restart_apiserver

    if timeout 5 kubectl get nodes &>/dev/null; then
        echo "  API server is running without encryption."
        sudo rm -f /tmp/kube-apiserver.yaml.backup-encryption
    else
        echo "  WARNING: API server failed to start. Check logs."
        echo "  Backup saved at: /tmp/kube-apiserver.yaml.backup-encryption"
    fi
}

# Function to force-delete a stuck namespace
force_delete_namespace() {
    local ns=$1

    if ! kubectl get namespace "$ns" &>/dev/null 2>&1; then
        return 0
    fi

    local phase=$(kubectl get namespace "$ns" -o jsonpath='{.status.phase}' 2>/dev/null)

    if [ "$phase" = "Terminating" ]; then
        echo "  Namespace $ns is stuck in Terminating, removing finalizers..."
        kubectl get namespace "$ns" -o json 2>/dev/null | \
            jq '.spec.finalizers = []' | \
            kubectl replace --raw "/api/v1/namespaces/${ns}/finalize" -f - 2>/dev/null || true

        # Wait a moment for deletion
        sleep 2

        if kubectl get namespace "$ns" &>/dev/null 2>&1; then
            echo "  WARNING: Namespace $ns still exists after finalizer removal."
        else
            echo "  Namespace $ns deleted successfully."
        fi
    fi
}

# ============================================================================
# MAIN RESET LOGIC
# ============================================================================

# Check if we're on a control plane node
if [ ! -f /etc/kubernetes/manifests/kube-apiserver.yaml ]; then
    echo "ERROR: This script must be run on a control plane node."
    exit 1
fi

# Step 1: If encryption is configured, decrypt all secrets first
if [ -f /etc/kubernetes/encryption-config.yaml ]; then
    decrypt_all_secrets
fi

# Step 2: Remove encryption configuration from API server
remove_encryption_config

# Step 3: Clean up resources (now safe because secrets are in plaintext)
echo "=== Step 3: Cleaning up resources ==="

# Delete secrets in secrets-ns first
if kubectl get namespace secrets-ns &>/dev/null 2>&1; then
    echo "  Deleting secrets in secrets-ns..."
    kubectl delete secret --all -n secrets-ns --ignore-not-found 2>/dev/null || true
fi

# Delete namespace
echo "  Deleting namespace secrets-ns..."
kubectl delete namespace secrets-ns --ignore-not-found --timeout=30s 2>/dev/null || true

# Force delete if stuck
force_delete_namespace "secrets-ns"

# Clean up other files
rm -rf /opt/course/09
sudo rm -rf /etc/kubernetes/enc 2>/dev/null || true

echo ""
echo "=== Question 09 Reset Complete! ==="
echo ""
echo "The encryption configuration has been removed and all secrets"
echo "have been re-encrypted to plaintext storage."
