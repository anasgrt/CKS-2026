#!/bin/bash
# Setup for Question 09 - Secrets Encryption

set -e

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
