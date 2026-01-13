#!/bin/bash
# Solution for Question 04 - RBAC Role

echo "Solution: Create RBAC resources for CI/CD pipeline"
echo ""
echo "Step 1: Create namespace and ServiceAccount"
echo ""

cat << 'EOF'
# Create namespace
kubectl create namespace cicd-ns

# Create ServiceAccount
cat > /opt/course/04/sa.yaml << 'YAML'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: deploy-sa
  namespace: cicd-ns
YAML

kubectl apply -f /opt/course/04/sa.yaml
EOF

echo ""
echo "Step 2: Create Role with deployment manager permissions"
echo ""

cat << 'EOF'
cat > /opt/course/04/role.yaml << 'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-manager
  namespace: cicd-ns
rules:
  # Full access to deployments
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  # Read access to pods and logs
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
  # Read access to services
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list"]
  # Read access to configmaps
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]
  # NO access to secrets - not included intentionally
YAML

kubectl apply -f /opt/course/04/role.yaml
EOF

echo ""
echo "Step 3: Create RoleBinding"
echo ""

cat << 'EOF'
cat > /opt/course/04/rolebinding.yaml << 'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deploy-sa-binding
  namespace: cicd-ns
subjects:
  - kind: ServiceAccount
    name: deploy-sa
    namespace: cicd-ns
roleRef:
  kind: Role
  name: deployment-manager
  apiGroup: rbac.authorization.k8s.io
YAML

kubectl apply -f /opt/course/04/rolebinding.yaml
EOF

echo ""
echo "Step 4: Test permissions"
echo ""

cat << 'EOF'
# Test deployment access (should return yes)
kubectl auth can-i create deployments --as=system:serviceaccount:cicd-ns:deploy-sa -n cicd-ns

# Test secrets access (should return no)
kubectl auth can-i get secrets --as=system:serviceaccount:cicd-ns:deploy-sa -n cicd-ns

# Save test output
{
  echo "Deployment create: $(kubectl auth can-i create deployments --as=system:serviceaccount:cicd-ns:deploy-sa -n cicd-ns)"
  echo "Secrets get: $(kubectl auth can-i get secrets --as=system:serviceaccount:cicd-ns:deploy-sa -n cicd-ns)"
  echo "Pods get: $(kubectl auth can-i get pods --as=system:serviceaccount:cicd-ns:deploy-sa -n cicd-ns)"
} > /opt/course/04/auth-test.txt
EOF

echo ""
echo "Key Points:"
echo "- Principle of least privilege: only grant necessary permissions"
echo "- Role is namespace-scoped, ClusterRole is cluster-wide"
echo "- apiGroups: ['apps'] for deployments, [''] for core resources"
echo "- Explicitly NOT including secrets access is a security requirement"
echo "- Use 'kubectl auth can-i' to verify permissions"
