#!/bin/bash
# Solution for Question 14 - Audit Logs

echo "Solution: Configure Kubernetes Audit Logging"
echo ""
echo "Step 1: Create audit policy"
echo ""

cat << 'EOF'
cat > /opt/course/14/audit-policy.yaml << 'YAML'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  # Log all secrets at RequestResponse level
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["secrets"]

  # Log all configmaps at Metadata level  
  - level: Metadata
    resources:
      - group: ""
        resources: ["configmaps"]

  # Log failed requests at Metadata level
  - level: Metadata
    omitStages:
      - RequestReceived
    # This catches errors via response codes

  # Don't log other requests
  - level: None
YAML

# Copy to audit directory
sudo mkdir -p /etc/kubernetes/audit
sudo cp /opt/course/14/audit-policy.yaml /etc/kubernetes/audit/policy.yaml
EOF

echo ""
echo "Step 2: Configure API server"
echo ""

cat << 'EOF'
# Edit /etc/kubernetes/manifests/kube-apiserver.yaml
# Add these flags to the command:

spec:
  containers:
  - command:
    - kube-apiserver
    - --audit-policy-file=/etc/kubernetes/audit/policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
    - --audit-log-maxage=7
    - --audit-log-maxbackup=3
    - --audit-log-maxsize=100
    # ... existing flags

# Add volume mounts:
    volumeMounts:
    - name: audit-policy
      mountPath: /etc/kubernetes/audit
      readOnly: true
    - name: audit-logs
      mountPath: /var/log/kubernetes/audit

# Add volumes:
  volumes:
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
echo "Step 3: Create a secret and capture audit log"
echo ""

cat << 'EOF'
# Create a test secret
kubectl create secret generic test-secret --from-literal=password=test -n audit-ns

# Wait for audit log to be written
sleep 5

# Find the secret creation audit entry
grep '"secrets"' /var/log/kubernetes/audit/audit.log | \
  grep 'test-secret' | \
  tail -1 > /opt/course/14/secret-audit.log
EOF

echo ""
echo "Audit Levels:"
echo "  None - Don't log"
echo "  Metadata - Log request metadata only"
echo "  Request - Log metadata + request body"
echo "  RequestResponse - Log metadata + request + response bodies"
echo ""
echo "Key Points:"
echo "- Audit policies are evaluated in order, first match wins"
echo "- RequestResponse logs can be large (include secret values!)"
echo "- Use Metadata level for most resources"
echo "- Forward logs to SIEM for analysis"
