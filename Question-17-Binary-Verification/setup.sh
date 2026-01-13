#!/bin/bash
# Setup for Question 17 - Binary Verification

set -e

# Create output directory
mkdir -p /opt/course/17

# Create a fake "suspicious" kubelet for the exercise
echo "This is a fake kubelet binary for testing" > /tmp/kubelet
chmod +x /tmp/kubelet

echo "Environment ready!"
echo ""
echo "Official checksums are at:"
echo "  https://dl.k8s.io/v1.30.0/bin/linux/amd64/kubectl.sha512"
echo "  https://dl.k8s.io/v1.30.0/bin/linux/amd64/kubelet.sha512"
echo ""
echo "Suspicious binary: /tmp/kubelet"
