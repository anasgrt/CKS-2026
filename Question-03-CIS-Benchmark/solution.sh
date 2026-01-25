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
Control Plane Fixes:
1. --anonymous-auth=false (CIS 1.2.1)
2. --profiling=false (CIS 1.2.18)
3. --authorization-mode=Node,RBAC (CIS 1.2.8)

Worker Node Fixes:
4. protect-kernel-defaults=true (CIS 4.2.6)
5. read-only-port=0 (CIS 4.2.4)
TXT
EOF

echo ""
echo "=== WORKER NODE (key-worker) ==="
echo ""
echo "# 4. Run kube-bench on worker"
echo "ssh key-worker 'kube-bench run --targets=node'"
echo ""
echo "# 5. Edit RKE2 config"
echo "ssh key-worker"
echo "sudo vim /etc/rancher/rke2/config.yaml"
cat << 'EOF'
# Add:
kubelet-arg:
- "protect-kernel-defaults=true"
- "read-only-port=0"

# Then restart:
sudo systemctl restart rke2-agent
EOF

echo ""
echo "# 6. Run kube-bench again"
echo "kube-bench run --targets=master > /opt/course/03/kube-bench-after.txt"
echo "ssh key-worker 'kube-bench run --targets=node' >> /opt/course/03/kube-bench-after.txt"
echo ""
echo "Key: API server manifest auto-restarts on save. Kubelet needs service restart."
