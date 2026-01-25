#!/bin/bash
# Reset Question 09 - Secrets Encryption

kubectl delete secret test-secret -n secrets-ns --ignore-not-found
kubectl delete namespace secrets-ns --ignore-not-found
rm -rf /opt/course/09

# Clean up encryption config files on control plane (if accessible)
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 controlplane 'test -d /etc/kubernetes/enc' 2>/dev/null; then
    echo "Cleaning up encryption config on controlplane..."
    ssh controlplane 'sudo rm -rf /etc/kubernetes/enc' 2>/dev/null || true
fi

echo "Question 09 reset complete!"
echo ""
echo "Note: If you modified the API server manifest to enable encryption,"
echo "      you must manually revert those changes:"
echo "      - Remove --encryption-provider-config flag"
echo "      - Remove related volumeMounts and volumes"
