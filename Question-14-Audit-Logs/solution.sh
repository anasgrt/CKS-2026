#!/bin/bash
# Solution for Question 14 - Audit Logs

echo "=== Step 1: Create Audit Policy ==="
cat << 'EOF'
cat > /opt/course/14/audit-policy.yaml << 'YAML'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
# 1. Exclude controller-leader configmap
- level: None
  resources:
  - group: ""
    resources: ["configmaps"]
    resourceNames: ["controller-leader"]

# 2. Exclude kube-proxy watch on endpoints/services
- level: None
  users: ["system:kube-proxy"]
  verbs: ["watch"]
  resources:
  - group: ""
    resources: ["endpoints", "services"]

# 3. kube-system changes at Request level
- level: Request
  namespaces: ["kube-system"]
  verbs: ["create", "update", "patch", "delete"]
  resources:
  - group: ""
    resources: ["configmaps", "secrets"]

# 4. Secrets at RequestResponse
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets"]

# 5. Pods at Metadata
- level: Metadata
  resources:
  - group: ""
    resources: ["pods", "pods/log"]

# 6. Catch-all
- level: Metadata
YAML

sudo mkdir -p /etc/kubernetes/audit
sudo cp /opt/course/14/audit-policy.yaml /etc/kubernetes/audit/policy.yaml
EOF

echo ""
echo "=== Step 2: Edit API Server (kubectl edit not available - use vim) ==="
echo "sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml"
cat << 'EOF'
# Add to command section:
    - --audit-policy-file=/etc/kubernetes/audit/policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
    - --audit-log-maxage=8
    - --audit-log-maxbackup=3
    - --audit-log-maxsize=9

# Add volumeMounts:
    - name: audit-policy
      mountPath: /etc/kubernetes/audit
      readOnly: true
    - name: audit-logs
      mountPath: /var/log/kubernetes/audit

# Add volumes:
  - name: audit-policy
    hostPath:
      path: /etc/kubernetes/audit
      type: DirectoryOrCreate
  - name: audit-logs
    hostPath:
      path: /var/log/kubernetes/audit
      type: DirectoryOrCreate
EOF

echo ""
echo "=== Step 3: Test and Capture Audit Log ==="
echo "kubectl create ns audit-test"
echo "kubectl create secret generic test-secret --from-literal=pass=secret -n audit-test"
echo "grep test-secret /var/log/kubernetes/audit/audit.log | tail -1 > /opt/course/14/secret-audit.log"
echo ""
echo "Key: First match wins! Order matters in audit policy rules."
