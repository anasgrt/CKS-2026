#!/bin/bash
# Solution for Question 03 - CIS Benchmark

echo "Solution: Fix CIS Benchmark violations"
echo ""
echo "Step 1: Run kube-bench and save output"
echo ""
echo "kube-bench run --targets=master > /opt/course/03/kube-bench-before.txt 2>&1"
echo ""
echo "Step 2: SSH to control plane node and edit API server manifest"
echo ""
echo "sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml"
echo ""
echo "Step 3: Add/modify these flags in the command section:"
echo ""

cat << 'EOF'
spec:
  containers:
  - command:
    - kube-apiserver
    - --anonymous-auth=false           # Add this line
    - --profiling=false                # Add this line
    - --authorization-mode=Node,RBAC   # Ensure RBAC is included
    # ... other existing flags
EOF

echo ""
echo "Step 4: Save your fixes summary"
echo ""

cat << 'EOF'
cat > /opt/course/03/fixes.txt << 'TXT'
CIS Benchmark Fixes Applied:

1. Set --anonymous-auth=false
   - Prevents unauthenticated access to API server
   - CIS 1.2.1

2. Added --profiling=false  
   - Disables profiling endpoint which can expose sensitive data
   - CIS 1.2.18

3. Verified --authorization-mode includes RBAC
   - Ensures proper authorization is enforced
   - CIS 1.2.8
TXT
EOF

echo ""
echo "Step 5: Wait for API server to restart (automatic when manifest changes)"
echo ""
echo "kubectl get pods -n kube-system | grep api"
echo ""
echo "Key Points:"
echo "- Static pod manifests are in /etc/kubernetes/manifests/"
echo "- kubelet watches this directory and restarts pods on change"
echo "- Always backup manifests before editing"
echo "- Run kube-bench again after fixes to verify"
