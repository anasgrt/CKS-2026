#!/bin/bash
# Solution for Question 16 - ImagePolicyWebhook
# Based on real CKS exam patterns (2025/2026)

echo "=============================================="
echo "Solution: Configure ImagePolicyWebhook"
echo "=============================================="
echo ""

echo "STEP 1: Complete the kubeconfig file"
echo "--------------------------------------"
echo "Edit /etc/kubernetes/admission/kubeconf.yaml"
echo ""

cat << 'EOF'
# Complete kubeconf.yaml should look like:

apiVersion: v1
kind: Config

# clusters refers to the remote webhook service
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/admission/external-cert.pem
    server: https://image-bouncer-webhook.default.svc:1323/image_policy
  name: image-checker

contexts:
- context:
    cluster: image-checker
    user: api-server
  name: image-checker

# CRITICAL: Set current-context
current-context: image-checker

preferences: {}

# users refers to the API server's webhook configuration
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/admission/apiserver-client-cert.pem
    client-key: /etc/kubernetes/admission/apiserver-client-key.pem
EOF

echo ""
echo "Command to apply:"
echo ""
cat << 'HEREDOC'
sudo tee /etc/kubernetes/admission/kubeconf.yaml << 'KUBECONF'
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/admission/external-cert.pem
    server: https://image-bouncer-webhook.default.svc:1323/image_policy
  name: image-checker
contexts:
- context:
    cluster: image-checker
    user: api-server
  name: image-checker
current-context: image-checker
preferences: {}
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/admission/apiserver-client-cert.pem
    client-key: /etc/kubernetes/admission/apiserver-client-key.pem
KUBECONF
HEREDOC

echo ""
echo "STEP 2: Complete the admission configuration"
echo "---------------------------------------------"
echo "Edit /etc/kubernetes/admission/admission_config.yaml"
echo ""

cat << 'EOF'
# Complete admission_config.yaml should look like:

apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/admission/kubeconf.yaml
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: false
EOF

echo ""
echo "Command to apply:"
echo ""
cat << 'HEREDOC'
sudo tee /etc/kubernetes/admission/admission_config.yaml << 'ADMISSIONCONF'
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/admission/kubeconf.yaml
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: false
ADMISSIONCONF
HEREDOC

echo ""
echo "STEP 3: Configure the kube-apiserver"
echo "-------------------------------------"
echo "Edit /etc/kubernetes/manifests/kube-apiserver.yaml"
echo ""

cat << 'EOF'
# Add/modify these sections in kube-apiserver.yaml:

# 1. Add to the command section (modify existing --enable-admission-plugins):
    - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook
    - --admission-control-config-file=/etc/kubernetes/admission/admission_config.yaml

# 2. Enable the imagepolicy.k8s.io/v1alpha1 API (add or modify --runtime-config):
    - --runtime-config=imagepolicy.k8s.io/v1alpha1=true

# 3. Add to volumeMounts section:
    - mountPath: /etc/kubernetes/admission
      name: admission
      readOnly: true

# 4. Add to volumes section:
  - hostPath:
      path: /etc/kubernetes/admission
      type: DirectoryOrCreate
    name: admission
EOF

echo ""
echo "Manual steps:"
echo ""
cat << 'HEREDOC'
# Edit the API server manifest:
sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml

# Find the line with --enable-admission-plugins and modify it to include ImagePolicyWebhook:
# Change FROM:
#   - --enable-admission-plugins=NodeRestriction
# TO:
#   - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook

# Add the admission-control-config-file flag:
#   - --admission-control-config-file=/etc/kubernetes/admission/admission_config.yaml

# Enable the imagepolicy.k8s.io/v1alpha1 API (add or modify --runtime-config):
#   - --runtime-config=imagepolicy.k8s.io/v1alpha1=true
# NOTE: If --runtime-config already exists, append with comma: api/all=true,imagepolicy.k8s.io/v1alpha1=true

# Add volumeMount under spec.containers[0].volumeMounts:
#   - mountPath: /etc/kubernetes/admission
#     name: admission
#     readOnly: true

# Add volume under spec.volumes:
#   - hostPath:
#       path: /etc/kubernetes/admission
#       type: DirectoryOrCreate
#     name: admission

# Save the file - API server will automatically restart
HEREDOC

echo ""
echo "STEP 4: Wait for API server and verify"
echo "---------------------------------------"
echo ""

cat << 'EOF'
# Wait for API server to restart (30-60 seconds)
# Check if API server is responding:
kubectl get nodes

# Once API server is back, test pod creation:
# Since we don't have a real webhook service running, pods will be DENIED
# because defaultAllow: false

kubectl run test-pod --image=nginx --dry-run=server

# Expected output (webhook unavailable, defaultAllow=false):
# Error from server (Forbidden): pods "test-pod" is forbidden:
# Post "https://image-bouncer-webhook.default.svc:1323/image_policy":
# dial tcp: lookup image-bouncer-webhook.default.svc: no such host
EOF

echo ""
echo "STEP 5: Save copies to /opt/course/16/"
echo "---------------------------------------"
echo ""

cat << 'HEREDOC'
sudo mkdir -p /opt/course/16
sudo cp /etc/kubernetes/admission/admission_config.yaml /opt/course/16/
sudo cp /etc/kubernetes/admission/kubeconf.yaml /opt/course/16/
HEREDOC

echo ""
echo "=============================================="
echo "KEY POINTS FOR THE EXAM:"
echo "=============================================="
echo ""
echo "1. The kubeconfig MUST have 'current-context' set - very common mistake!"
echo ""
echo "2. 'defaultAllow: false' is the secure setting (fail-closed):"
echo "   - false = DENY pods if webhook unreachable (secure)"
echo "   - true  = ALLOW pods if webhook unreachable (insecure)"
echo ""
echo "3. The ImagePolicyWebhook uses a kubeconfig-style file to configure:"
echo "   - Which webhook server to contact (clusters.cluster.server)"
echo "   - How to authenticate (users.user with client certs)"
echo "   - Which CA to trust (clusters.cluster.certificate-authority)"
echo ""
echo "4. Volume mounts are REQUIRED for the API server to access:"
echo "   - The admission config file"
echo "   - The kubeconfig file"
echo "   - The certificates"
echo ""
echo "5. After modifying the API server manifest:"
echo "   - The kubelet automatically restarts the API server"
echo "   - Wait 30-60 seconds before running kubectl commands"
echo "   - Use 'crictl ps' to check if apiserver container is running"
echo ""
echo "6. If API server doesn't come back:"
echo "   - Check logs: crictl logs \$(crictl ps -a | grep kube-apiserver | awk '{print \$1}')"
echo "   - Common issues: typos in paths, missing volumes, YAML syntax errors"
echo ""
echo "Documentation: https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#imagepolicywebhook"
echo ""
