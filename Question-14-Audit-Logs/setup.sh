#!/bin/bash
# Setup for Question 14 - Audit Logs

set -e

# Create namespace
kubectl create namespace audit-ns --dry-run=client -o yaml | kubectl apply -f -

# Create output directory
mkdir -p /opt/course/14

echo "Environment ready!"
echo "Namespace: audit-ns"
echo ""
echo "Important paths:"
echo "  API server manifest: /etc/kubernetes/manifests/kube-apiserver.yaml"
echo "  Audit policy: /etc/kubernetes/audit/policy.yaml"
echo "  Audit logs: /var/log/kubernetes/audit/"
echo ""
echo "Audit levels: None, Metadata, Request, RequestResponse"
