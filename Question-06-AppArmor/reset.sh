#!/bin/bash
# Reset Question 06 - AppArmor

# Delete the secured-pod created by user
kubectl delete pod secured-pod -n apparmor-ns --ignore-not-found 2>/dev/null

# Delete namespace (setup creates it but reset should clean it)
kubectl delete namespace apparmor-ns --ignore-not-found 2>/dev/null

# Clean up output directory
rm -rf /opt/course/06

# Note: AppArmor profile 'k8s-deny-write' is kept on node01 as it's part of the setup infrastructure

echo "Question 06 reset complete!"
