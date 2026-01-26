#!/bin/bash
# Setup for Question 09 - Secrets Encryption

set -e

# Install etcdctl if not present
if ! command -v etcdctl &> /dev/null; then
    echo "Installing etcdctl..."
    apt-get update && apt-get install -y etcd-client
fi

# Clean up any corrupted secrets from previous attempts
# This prevents "invalid padding" errors when practicing this question multiple times
echo "Checking for corrupted secrets from previous attempts..."
ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets --prefix --keys-only 2>/dev/null | while read key; do
    [ -z "$key" ] && continue
    ns=$(echo "$key" | cut -d'/' -f4)
    name=$(echo "$key" | cut -d'/' -f5)
    if [ -n "$ns" ] && [ -n "$name" ]; then
      if ! kubectl get secret "$name" -n "$ns" &>/dev/null 2>&1; then
        echo "  Cleaning corrupted secret: $ns/$name"
        ETCDCTL_API=3 etcdctl \
          --cacert=/etc/kubernetes/pki/etcd/ca.crt \
          --cert=/etc/kubernetes/pki/etcd/server.crt \
          --key=/etc/kubernetes/pki/etcd/server.key \
          del "$key" 2>/dev/null || true
      fi
    fi
done
echo "Corrupted secrets cleanup complete."
echo ""

# Create namespace
kubectl create namespace secrets-ns --dry-run=client -o yaml | kubectl apply -f -

# Create output directory
mkdir -p /opt/course/09

echo "Environment ready!"
echo "Namespace: secrets-ns"
echo ""
echo "Important paths:"
echo "  EncryptionConfig location: /etc/kubernetes/enc/"
echo "  API server manifest: /etc/kubernetes/manifests/kube-apiserver.yaml"
echo ""
echo "Generate a 32-byte base64 key with:"
echo "  head -c 32 /dev/urandom | base64"
