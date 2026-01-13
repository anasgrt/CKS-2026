#!/bin/bash
# Solution for Question 07 - Seccomp

echo "Solution: Configure Seccomp profiles"
echo ""
echo "Step 1: Create namespace"
echo ""

cat << 'EOF'
kubectl create namespace seccomp-ns
mkdir -p /opt/course/07
EOF

echo ""
echo "Step 2: Create RuntimeDefault Seccomp pod"
echo ""

cat << 'EOF'
cat > /opt/course/07/runtime-default-pod.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: runtime-default-pod
  namespace: seccomp-ns
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      seccompProfile:
        type: RuntimeDefault
YAML

kubectl apply -f /opt/course/07/runtime-default-pod.yaml
EOF

echo ""
echo "Step 3: Create Custom Seccomp pod (using audit-log.json)"
echo ""

cat << 'EOF'
cat > /opt/course/07/custom-seccomp-pod.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: custom-seccomp-pod
  namespace: seccomp-ns
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      seccompProfile:
        type: Localhost
        localhostProfile: audit-log.json
YAML

kubectl apply -f /opt/course/07/custom-seccomp-pod.yaml
EOF

echo ""
echo "Step 4: Verify seccomp is applied"
echo ""

cat << 'EOF'
# Check seccomp configuration
kubectl describe pod runtime-default-pod -n seccomp-ns | grep -i seccomp > /opt/course/07/seccomp-verify.txt
kubectl describe pod custom-seccomp-pod -n seccomp-ns | grep -i seccomp >> /opt/course/07/seccomp-verify.txt
EOF

echo ""
echo "Key Points:"
echo "- Seccomp filters system calls to reduce attack surface"
echo "- RuntimeDefault uses the container runtime's default profile"
echo "- Localhost profiles are stored at /var/lib/kubelet/seccomp/"
echo "- localhostProfile is relative to the seccomp directory"
echo "- Types: RuntimeDefault, Localhost, Unconfined"
echo "- audit-log.json profile logs syscall usage for analysis"
echo "- Always test custom profiles before production use"
