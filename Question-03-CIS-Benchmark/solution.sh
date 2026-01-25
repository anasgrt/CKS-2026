#!/bin/bash
# Solution for Question 03 - CIS Benchmark (kubeadm cluster)

echo "=== CONTROL PLANE (controlplane) ==="
echo ""
echo "# 1. Run kube-bench and save"
echo "kube-bench run --targets=master > /opt/course/03/kube-bench-before.txt"
echo ""
echo "# 2. Edit API server manifest"
echo "sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml"
cat << 'EOF'
# Fix these flags in the command section:
    - --anonymous-auth=false      # (change from true)
    - --profiling=false           # (add or change from true)
    - --authorization-mode=Node,RBAC  # (add Node)
EOF

echo ""
echo "# 3. Write fixes.txt"
cat << 'EOF'
cat > /opt/course/03/fixes.txt << 'TXT'
Control Plane Fixes (/etc/kubernetes/manifests/kube-apiserver.yaml):
1. --anonymous-auth=false (CIS 1.2.1)
2. --profiling=false (CIS 1.2.21)
3. --authorization-mode=Node,RBAC (CIS 1.2.8)

Worker Node Fixes (/var/lib/kubelet/config.yaml on node01):
4. protectKernelDefaults: true (CIS 4.2.6)
TXT
EOF

echo ""
echo "=== WORKER NODE (node01) ==="
echo ""
echo "# 4. Run kube-bench on worker"
echo "ssh node01 'kube-bench run --targets=node'"
echo ""
echo "# 5. Fix protect-kernel-defaults (CIS 4.2.6)"
echo "ssh node01"
cat << 'EOF'
# Edit kubelet config
sudo vim /var/lib/kubelet/config.yaml

# Add this line:
protectKernelDefaults: true

# Restart kubelet
sudo systemctl restart kubelet

# Verify:
sudo systemctl status kubelet
EOF

echo ""
echo "# 6. Run kube-bench again"
echo "kube-bench run --targets=master > /opt/course/03/kube-bench-after.txt"
echo "ssh node01 'kube-bench run --targets=node' >> /opt/course/03/kube-bench-after.txt"
echo ""
echo "Key: API server manifest auto-restarts on save. Kubelet needs 'systemctl restart kubelet'."
