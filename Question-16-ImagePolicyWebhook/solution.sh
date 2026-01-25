#!/bin/bash
# Solution for Question 16 - ImagePolicyWebhook

echo "Solution: Configure ImagePolicyWebhook"
echo ""
echo "Step 1: Create kubeconfig for webhook"
echo ""

cat << 'EOF'
cat > /opt/course/16/image-policy-kubeconfig.yaml << 'YAML'
apiVersion: v1
kind: Config
clusters:
  - name: image-policy-webhook
    cluster:
      server: https://image-policy-webhook.image-policy.svc:443
      certificate-authority: /etc/kubernetes/pki/image-policy/ca.crt
contexts:
  - name: image-policy
    context:
      cluster: image-policy-webhook
current-context: image-policy
YAML
EOF

echo ""
echo "Step 2: Create admission configuration"
echo ""

cat << 'EOF'
cat > /opt/course/16/admission-config.yaml << 'YAML'
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
  - name: ImagePolicyWebhook
    configuration:
      imagePolicy:
        kubeConfigFile: /etc/kubernetes/admission/image-policy-kubeconfig.yaml
        allowTTL: 50
        denyTTL: 50
        retryBackoff: 500
        defaultAllow: false
YAML
EOF

echo ""
echo "Step 3: Copy files to API server"
echo ""

cat << 'EOF'
sudo mkdir -p /etc/kubernetes/admission
sudo cp /opt/course/16/admission-config.yaml /etc/kubernetes/admission/
sudo cp /opt/course/16/image-policy-kubeconfig.yaml /etc/kubernetes/admission/
EOF

echo ""
echo "Step 4: Configure API server"
echo ""

cat << 'EOF'
# Edit /var/lib/rancher/rke2/agent/pod-manifests/kube-apiserver.yaml
# Add/modify these flags:

    - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook
    - --admission-control-config-file=/etc/kubernetes/admission/admission-config.yaml

# Add volume mounts and volumes for the admission directory
EOF

echo ""
echo "Step 5: Test the configuration"
echo ""

cat << 'EOF'
# Try to create a pod with untrusted image (should be denied)
kubectl run test --image=docker.io/malicious/image

# If webhook denies, you'll see:
# Error: admission webhook denied the request
EOF

echo ""
echo "Key Points:"
echo "- defaultAllow: false is more secure (fail-closed)"
echo "- Webhook must respond within timeout or default behavior applies"
echo "- Use for enforcing signed images, registry allowlists, etc."
echo "- Can be combined with ValidatingWebhookConfiguration for more flexibility"
