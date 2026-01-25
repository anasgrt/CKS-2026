#!/bin/bash
# Solution for Question 05 - ServiceAccount Security

echo "=== Quick Solution ==="
echo ""
echo "# 1. Create ServiceAccount with automountServiceAccountToken: false"
cat << 'EOF'
cat <<YAML | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: restricted-sa
  namespace: secure-ns
automountServiceAccountToken: false
YAML
EOF

echo ""
echo "# 2. Create Role and RoleBinding"
echo "kubectl create role pod-reader -n secure-ns --verb=get,list --resource=pods,services"
echo "kubectl create rolebinding restricted-sa-binding -n secure-ns --role=pod-reader --serviceaccount=secure-ns:restricted-sa"
echo ""

echo "# 3. Update deployment (use kubectl edit - SIMPLEST for exam)"
echo "kubectl edit deployment insecure-app -n secure-ns"
cat << 'EOF'
# Add these two lines under spec.template.spec:
  serviceAccountName: restricted-sa
  automountServiceAccountToken: false
EOF

echo ""
echo "# 4. Verify token NOT mounted"
echo "kubectl exec <pod-name> -n secure-ns -- ls /var/run/secrets/kubernetes.io/serviceaccount/"
echo "# Should fail or show empty"
echo ""

echo "# 5. Save files"
echo "kubectl get sa restricted-sa -n secure-ns -o yaml > /opt/course/05/sa.yaml"
echo "kubectl get role pod-reader -n secure-ns -o yaml > /opt/course/05/role.yaml"
echo "kubectl get rolebinding restricted-sa-binding -n secure-ns -o yaml > /opt/course/05/rolebinding.yaml"
echo "kubectl get deployment insecure-app -n secure-ns -o yaml > /opt/course/05/deployment.yaml"
echo ""
echo "Key: automountServiceAccountToken: false prevents token theft if container compromised."
