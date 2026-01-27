#!/bin/bash
# Reset Question 16 - ImagePolicyWebhook
# Based on real CKS exam patterns (2025/2026)

echo "Resetting ImagePolicyWebhook scenario..."
echo ""

# Remove output directory
sudo rm -rf /opt/course/16

# Remove admission configuration files
if [ -d "/etc/kubernetes/admission" ]; then
    echo "Removing admission configuration directory..."
    sudo rm -rf /etc/kubernetes/admission
fi

# Restore API server manifest if backup exists
if [ -f "/etc/kubernetes/manifests/kube-apiserver.yaml.bak" ]; then
    echo "Restoring API server manifest from backup..."
    sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml
    echo "Waiting for API server to restart..."
    sleep 30
fi

echo ""
echo "Question 16 reset complete!"
echo ""
echo "=============================================="
echo "IMPORTANT MANUAL STEPS (if you modified the API server):"
echo "=============================================="
echo ""
echo "If the API server manifest was modified, you need to manually revert:"
echo ""
echo "1. Edit /etc/kubernetes/manifests/kube-apiserver.yaml"
echo ""
echo "2. Remove ImagePolicyWebhook from --enable-admission-plugins:"
echo "   Change: --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook"
echo "   To:     --enable-admission-plugins=NodeRestriction"
echo ""
echo "3. Remove the --admission-control-config-file flag entirely"
echo ""
echo "4. If you added --runtime-config=imagepolicy.k8s.io/v1alpha1=true, remove it"
echo ""
echo "5. Remove the volumeMount for admission:"
echo "   - mountPath: /etc/kubernetes/admission"
echo "     name: admission"
echo "     readOnly: true"
echo ""
echo "6. Remove the volume for admission:"
echo "   - hostPath:"
echo "       path: /etc/kubernetes/admission"
echo "       type: DirectoryOrCreate"
echo "     name: admission"
echo ""
echo "7. Wait 30-60 seconds for API server to restart"
echo ""
echo "Pro tip: Before modifying API server, create a backup:"
echo "  sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml.bak"
echo ""
