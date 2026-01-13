#!/bin/bash
# Setup for Question 15 - RuntimeClass Sandbox

set -e

# Create namespace
kubectl create namespace sandbox-ns --dry-run=client -o yaml | kubectl apply -f -

# Create RuntimeClass (simulated gVisor)
cat << 'EOF' | kubectl apply -f -
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
EOF

# Create output directory
mkdir -p /opt/course/15

echo "Environment ready!"
echo "Namespace: sandbox-ns"
echo "RuntimeClass: gvisor (handler: runsc)"
echo ""
echo "Note: In a real cluster, gVisor must be installed on nodes."
echo "Check available RuntimeClasses: kubectl get runtimeclass"
