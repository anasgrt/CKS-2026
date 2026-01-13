#!/bin/bash
# Solution for Question 05 - ServiceAccount Security

echo "Solution: Secure ServiceAccount configuration"
echo ""
echo "Step 1: Create restricted ServiceAccount"
echo ""

cat << 'EOF'
mkdir -p /opt/course/05

cat > /opt/course/05/sa.yaml << 'YAML'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: restricted-sa
  namespace: secure-ns
automountServiceAccountToken: false
YAML

kubectl apply -f /opt/course/05/sa.yaml
EOF

echo ""
echo "Step 2: Create pod-reader Role"
echo ""

cat << 'EOF'
cat > /opt/course/05/role.yaml << 'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: secure-ns
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list"]
YAML

kubectl apply -f /opt/course/05/role.yaml
EOF

echo ""
echo "Step 3: Create RoleBinding"
echo ""

cat << 'EOF'
cat > /opt/course/05/rolebinding.yaml << 'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: restricted-sa-binding
  namespace: secure-ns
subjects:
  - kind: ServiceAccount
    name: restricted-sa
    namespace: secure-ns
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
YAML

kubectl apply -f /opt/course/05/rolebinding.yaml
EOF

echo ""
echo "Step 4: Update the deployment"
echo ""

cat << 'EOF'
# Get current deployment and modify it
kubectl get deployment insecure-app -n secure-ns -o yaml > /opt/course/05/deployment.yaml

# Edit /opt/course/05/deployment.yaml to add:
# spec.template.spec.serviceAccountName: restricted-sa
# spec.template.spec.automountServiceAccountToken: false

# Or use patch:
kubectl patch deployment insecure-app -n secure-ns --type=json -p='[
  {"op": "add", "path": "/spec/template/spec/serviceAccountName", "value": "restricted-sa"},
  {"op": "add", "path": "/spec/template/spec/automountServiceAccountToken", "value": false}
]'
EOF

echo ""
echo "Step 5: Verify token is not mounted"
echo ""

cat << 'EOF'
# This should fail (directory doesn't exist)
kubectl exec <pod-name> -n secure-ns -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
EOF

echo ""
echo "Key Points:"
echo "- automountServiceAccountToken prevents the token from being mounted"
echo "- Setting it at SA level affects all pods using that SA"
echo "- Setting it at pod level overrides the SA setting"
echo "- Best practice: set it at both levels for defense in depth"
echo "- This prevents token theft if container is compromised"
echo "- pod-reader role has minimal permissions (no secrets access)"
