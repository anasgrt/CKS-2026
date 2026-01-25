#!/bin/bash
# Reset Question 16 - ImagePolicyWebhook

rm -rf /opt/course/16

# Clean up admission config files on control plane (if accessible)
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 key-ctrl 'test -d /etc/kubernetes/admission' 2>/dev/null; then
    echo "Cleaning up admission config on key-ctrl..."
    ssh key-ctrl 'sudo rm -rf /etc/kubernetes/admission' 2>/dev/null || true
fi

echo "Question 16 reset complete!"
echo ""
echo "Note: If you modified the API server manifest to enable ImagePolicyWebhook,"
echo "      you must manually revert those changes:"
echo "      - Remove ImagePolicyWebhook from --enable-admission-plugins"
echo "      - Remove --admission-control-config-file flag"
echo "      - Remove related volumeMounts and volumes"
