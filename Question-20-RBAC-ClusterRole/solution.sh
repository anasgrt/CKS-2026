#!/bin/bash
# Solution for Question 20 - RBAC ClusterRole

echo "=== Quick Solution (kubectl create commands) ==="
echo ""
echo "# 1. Create ServiceAccount"
echo "kubectl create sa monitor-sa -n monitoring"
echo ""
echo "# 2. Create ClusterRole (read-only pods/nodes/namespaces, get pods/log and events)"
echo "kubectl create clusterrole cluster-monitor \\"
echo "  --verb=get,list,watch --resource=pods,nodes,namespaces \\"
echo "  --verb=get --resource=pods/log,endpoints,services \\"
echo "  --verb=get,list --resource=events"
echo ""
echo "# 3. Create ClusterRoleBinding"
echo "kubectl create clusterrolebinding cluster-monitor-binding \\"
echo "  --clusterrole=cluster-monitor --serviceaccount=monitoring:monitor-sa"
echo ""
echo "# 4. Test permissions"
echo "kubectl auth can-i list pods -A --as=system:serviceaccount:monitoring:monitor-sa"
echo "kubectl auth can-i get secrets -A --as=system:serviceaccount:monitoring:monitor-sa  # should be NO"
echo ""
echo "# 5. Save files"
echo "kubectl get sa monitor-sa -n monitoring -o yaml > /opt/course/20/sa.yaml"
echo "kubectl get clusterrole cluster-monitor -o yaml > /opt/course/20/clusterrole.yaml"
echo "kubectl get clusterrolebinding cluster-monitor-binding -o yaml > /opt/course/20/clusterrolebinding.yaml"
echo ""

echo "=== If kubectl create doesn't work, use YAML ==="
cat << 'EOF'
cat <<YAML | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-monitor
rules:
- apiGroups: [""]
  resources: ["pods", "nodes", "namespaces"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log", "endpoints", "services"]
  verbs: ["get"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list"]
YAML
EOF

echo ""
echo "Key: ClusterRole = cluster-wide, ClusterRoleBinding grants access across ALL namespaces."
