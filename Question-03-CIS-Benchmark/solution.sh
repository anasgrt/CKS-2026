#!/bin/bash
# Solution for Question 03 - CIS Benchmark

echo "=== CONTROL PLANE (key-ctrl) ==="
echo ""
echo "# 1. Run kube-bench and save"
echo "kube-bench run --targets=master > /opt/course/03/kube-bench-before.txt"
echo ""
echo "# 2. Edit API server manifest"
echo "sudo vim /var/lib/rancher/rke2/agent/pod-manifests/kube-apiserver.yaml"
cat << 'EOF'
# Add these flags to command section:
    - --anonymous-auth=false
    - --profiling=false
    - --authorization-mode=Node,RBAC
EOF

echo ""
echo "# 3. Write fixes.txt"
cat << 'EOF'
cat > /opt/course/03/fixes.txt << 'TXT'
Control Plane Fixes (kube-apiserver.yaml):
1. --anonymous-auth=false (CIS 1.2.1)
2. --profiling=false (CIS 1.2.21)
3. --authorization-mode=Node,RBAC (CIS 1.2.8)

Worker Node Fixes:
4. chmod 600 on kubelet service file (CIS 4.1.1)
TXT
EOF

echo ""
echo "=== WORKER NODE (key-worker) ==="
echo ""
echo "# 4. Run kube-bench on worker"
echo "ssh key-worker 'kube-bench run --targets=node'"
echo ""
echo "# 5. Fix kubelet service file permissions (CIS 4.1.1)"
echo "ssh key-worker"
cat << 'EOF'
# The kubelet service file has 644 permissions, should be 600
sudo chmod 600 /usr/local/lib/systemd/system/rke2-agent.service

# Verify the fix:
stat /usr/local/lib/systemd/system/rke2-agent.service | grep Access
# Should show: Access: (0600/-rw-------)
EOF

echo ""
echo "# 6. Run kube-bench again"
echo "kube-bench run --targets=master > /opt/course/03/kube-bench-after.txt"
echo "ssh key-worker 'kube-bench run --targets=node' >> /opt/course/03/kube-bench-after.txt"
echo ""
echo "Key: API server manifest auto-restarts on save. Kubelet needs service restart."
