#!/bin/bash
# Solution for Question 06 - AppArmor

echo "Solution: Configure AppArmor profile for pod"
echo ""
echo "Step 1: Verify AppArmor profile is loaded on the node"
echo ""

cat << 'EOF'
# SSH to worker node and check profile
ssh key-worker
aa-status | grep k8s-deny-write

# If not loaded, load it:
sudo apparmor_parser -q /etc/apparmor.d/k8s-deny-write
EOF

echo ""
echo "Step 2: Create the pod with AppArmor securityContext (K8s 1.30+ GA syntax)"
echo ""

cat << 'EOF'
mkdir -p /opt/course/06

cat > /opt/course/06/pod.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: secured-pod
  namespace: apparmor-ns
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      appArmorProfile:
        type: Localhost
        localhostProfile: k8s-deny-write
YAML

kubectl apply -f /opt/course/06/pod.yaml
EOF

echo ""
echo "Step 3: Verify AppArmor is enforced"
echo ""

cat << 'EOF'
# Wait for pod to be ready
kubectl wait --for=condition=Ready pod/secured-pod -n apparmor-ns --timeout=30s

# Test that write is denied
kubectl exec secured-pod -n apparmor-ns -- touch /test-file 2>&1 | tee /opt/course/06/apparmor-test.txt

# Should see "Permission denied" or "Read-only file system"

# Verify AppArmor profile is applied
kubectl get pod secured-pod -n apparmor-ns -o jsonpath='{.spec.containers[0].securityContext.appArmorProfile}'
EOF

echo ""
echo "Key Points:"
echo "- AppArmor profiles must be loaded on the node BEFORE pod creation"
echo "- Use 'aa-status' to list loaded profiles"
echo "- Kubernetes 1.30+ uses securityContext.appArmorProfile (GA)"
echo "- type: Localhost means the profile is on the node's filesystem"
echo "- localhostProfile: name of the profile (without 'localhost/' prefix)"
echo "- Profile files are typically in /etc/apparmor.d/"
echo ""
echo "Note: The annotation method (container.apparmor.security.beta.kubernetes.io)"
echo "is DEPRECATED and should not be used for CKS 2026 exam."
