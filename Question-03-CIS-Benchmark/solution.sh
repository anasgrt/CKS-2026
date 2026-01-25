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

Worker Node Analysis:
4. CIS 4.1.1 FAIL - False positive: kube-bench checks /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
   which does not exist on RKE2. The equivalent RKE2 file is:
   /usr/local/lib/systemd/system/rke2-agent.service (permissions 644, already acceptable)
TXT
EOF

echo ""
echo "=== WORKER NODE (key-worker) ==="
echo ""
echo "# 4. Run kube-bench on worker"
echo "ssh key-worker 'kube-bench run --targets=node'"
echo ""
echo "# 5. Worker node analysis (CIS 4.1.1)"
echo "ssh key-worker"
cat << 'EOF'
# NOTE: kube-bench 4.1.1 shows FAIL because it checks for:
#   /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# This file does NOT exist on RKE2 - it's a kubeadm-specific path.

# On RKE2, the kubelet runs via rke2-agent.service. Check its permissions:
stat /usr/local/lib/systemd/system/rke2-agent.service
# Shows: 644 (acceptable, but 600 would be more restrictive)

# Optional: To make it more restrictive:
sudo chmod 600 /usr/local/lib/systemd/system/rke2-agent.service

# The 4.1.1 FAIL is a FALSE POSITIVE for RKE2 systems.
# In a real exam, document this in your fixes.txt as "Not applicable to RKE2"
EOF

echo ""
echo "# 6. Run kube-bench again"
echo "kube-bench run --targets=master > /opt/course/03/kube-bench-after.txt"
echo "ssh key-worker 'kube-bench run --targets=node' >> /opt/course/03/kube-bench-after.txt"
echo ""
echo "Key: API server manifest auto-restarts on save. Kubelet needs service restart."
