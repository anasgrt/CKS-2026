#!/bin/bash
# Setup for Question 17 - Binary Verification

set -e

# Create output directory
mkdir -p /opt/course/17

# Create a fake "suspicious" kubelet for the exercise
# This simulates a potentially tampered binary that the user must verify
echo "This is a fake kubelet binary for testing - possibly tampered!" > /tmp/kubelet-suspicious
chmod +x /tmp/kubelet-suspicious

echo "Environment ready!"
echo ""
echo "Official checksums are at:"
echo "  https://dl.k8s.io/v1.30.0/bin/linux/amd64/kubectl.sha512"
echo "  https://dl.k8s.io/v1.30.0/bin/linux/amd64/kubelet.sha512"
echo ""
echo "Suspicious binary: /tmp/kubelet-suspicious"
echo ""
echo "Example verification commands:"
echo "  sha512sum /usr/local/bin/kubectl"
echo "  echo '<expected-checksum>  /path/to/binary' | sha512sum -c"
