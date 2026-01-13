#!/bin/bash
# Solution for Question 15 - RuntimeClass Sandbox

echo "Solution: Create pod with RuntimeClass"
echo ""

cat << 'EOF'
cat > /opt/course/15/pod.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: sandboxed-pod
  namespace: sandbox-ns
spec:
  runtimeClassName: gvisor
  containers:
  - name: nginx
    image: nginx
YAML

kubectl apply -f /opt/course/15/pod.yaml
EOF

echo ""
echo "Verify the runtime:"
echo "kubectl get pod sandboxed-pod -n sandbox-ns -o jsonpath='{.spec.runtimeClassName}'"
echo ""
echo "If gVisor is properly installed, verify with:"
echo "kubectl exec sandboxed-pod -n sandbox-ns -- dmesg | head"
echo "# Should show 'Starting gVisor...'"
echo ""
echo "Key Points:"
echo "- RuntimeClass maps to a container runtime handler"
echo "- gVisor (runsc) provides kernel-level sandboxing"
echo "- Kata Containers provides VM-level isolation"
echo "- Check node has the runtime: crictl info"
echo "- RuntimeClass is cluster-scoped (no namespace)"
