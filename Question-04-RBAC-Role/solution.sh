#!/bin/bash
# Solution for Question 04 - RBAC Role

echo "=== Quick Solution (kubectl create commands) ==="
echo ""
echo "# 1. Create namespace and ServiceAccount"
echo "kubectl create namespace cicd-ns"
echo "kubectl create serviceaccount deploy-sa -n cicd-ns"
echo ""
echo "# 2. Create Role (full deployments, read-only pods/services/configmaps, NO secrets)"
echo "kubectl create role deployment-manager -n cicd-ns \\"
echo "  --verb=get,list,watch,create,update,patch,delete --resource=deployments.apps \\"
echo "  --verb=get,list,watch --resource=pods,pods/log \\"
echo "  --verb=get,list --resource=services,configmaps"
echo ""
echo "# 3. Create RoleBinding"
echo "kubectl create rolebinding deploy-sa-binding -n cicd-ns \\"
echo "  --role=deployment-manager --serviceaccount=cicd-ns:deploy-sa"
echo ""
echo "# 4. Test permissions"
echo "kubectl auth can-i create deployments --as=system:serviceaccount:cicd-ns:deploy-sa -n cicd-ns"
echo "kubectl auth can-i get secrets --as=system:serviceaccount:cicd-ns:deploy-sa -n cicd-ns"
echo ""
echo "# 5. Save output files (for exam requirements)"
echo "kubectl get sa deploy-sa -n cicd-ns -o yaml > /opt/course/04/sa.yaml"
echo "kubectl get role deployment-manager -n cicd-ns -o yaml > /opt/course/04/role.yaml"
echo "kubectl get rolebinding deploy-sa-binding -n cicd-ns -o yaml > /opt/course/04/rolebinding.yaml"
echo ""

echo "=== Alternative: YAML Method ==="
cat << 'EOF'
# If kubectl create doesn't support all verbs, use YAML:

cat <<YAML | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-manager
  namespace: cicd-ns
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["services", "configmaps"]
  verbs: ["get", "list"]
YAML
EOF

echo ""
echo "Key: apiGroups ['apps'] for deployments, [''] for core resources. NO secrets = security."
