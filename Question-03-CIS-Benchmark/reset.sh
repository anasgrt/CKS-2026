#!/bin/bash
# Reset Question 03 - CIS Benchmark

# Clean up output directory
rm -rf /opt/course/03

echo "Question 03 reset complete!"
echo ""
echo "Note: kube-bench tool is kept installed on nodes as infrastructure."
echo "If you modified /var/lib/rancher/rke2/agent/pod-manifests/kube-apiserver.yaml on key-ctrl,"
echo "you must manually revert those changes."
