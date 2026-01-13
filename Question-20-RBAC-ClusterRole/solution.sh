#!/bin/bash
# Solution for Question 20 - RBAC ClusterRole

echo "Solution: Create Cluster-wide RBAC for monitoring"
echo ""
echo "Step 1: Create ServiceAccount"
echo ""

cat << 'EOF'
cat > /opt/course/20/sa.yaml << 'YAML'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: monitor-sa
  namespace: monitoring
YAML

kubectl apply -f /opt/course/20/sa.yaml
EOF

echo ""
echo "Step 2: Create ClusterRole"
echo ""

cat << 'EOF'
cat > /opt/course/20/clusterrole.yaml << 'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-monitor
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["endpoints", "services"]
    verbs: ["get"]
YAML

kubectl apply -f /opt/course/20/clusterrole.yaml
EOF

echo ""
echo "Step 3: Create ClusterRoleBinding"
echo ""

cat << 'EOF'
cat > /opt/course/20/clusterrolebinding.yaml << 'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-monitor-binding
subjects:
  - kind: ServiceAccount
    name: monitor-sa
    namespace: monitoring
roleRef:
  kind: ClusterRole
  name: cluster-monitor
  apiGroup: rbac.authorization.k8s.io
YAML

kubectl apply -f /opt/course/20/clusterrolebinding.yaml
EOF

echo ""
echo "Step 4: Verify access"
echo ""

cat << 'EOF'
# Test with kubectl auth can-i
kubectl auth can-i list pods --all-namespaces --as=system:serviceaccount:monitoring:monitor-sa

# Or run a pod with the ServiceAccount and test
kubectl run test-access --image=bitnami/kubectl --rm -it --restart=Never \
  --serviceaccount=monitor-sa -n monitoring -- kubectl get pods -A
EOF

echo ""
echo "Quick command alternatives:"
echo ""
echo "kubectl create sa monitor-sa -n monitoring"
echo "kubectl create clusterrole cluster-monitor --verb=get,list,watch --resource=pods,nodes --verb=get,list --resource=namespaces --verb=get --resource=pods/log"
echo "kubectl create clusterrolebinding cluster-monitor-binding --clusterrole=cluster-monitor --serviceaccount=monitoring:monitor-sa"
echo ""
echo "Key Points:"
echo "- ClusterRole is cluster-scoped (not namespaced)"
echo "- ClusterRoleBinding grants cluster-wide access"
echo "- pods/log is a subresource - requires separate rule"
echo "- Use 'kubectl auth can-i' to test permissions"
echo "- Follow least privilege principle"
