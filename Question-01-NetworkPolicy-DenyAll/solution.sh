#!/bin/bash
# Solution for Question 01 - NetworkPolicy Default Deny

echo "Solution: Create default-deny NetworkPolicy"
echo ""
echo "Step 1: Create the NetworkPolicy YAML file"
echo ""

cat << 'EOF'
cat > /opt/course/01/netpol.yaml << 'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: isolated-ns
spec:
  podSelector: {}          # Empty selector matches ALL pods
  policyTypes:
    - Ingress              # Block all incoming traffic
    - Egress               # Block all outgoing traffic
  # No ingress or egress rules = deny all
YAML
EOF

echo ""
echo "Step 2: Apply the NetworkPolicy"
echo ""
echo "kubectl apply -f /opt/course/01/netpol.yaml"

echo ""
echo "Step 3: Create a test pod and verify traffic is blocked"
echo ""

cat << 'EOF'
# Create a test pod
kubectl run test-pod -n isolated-ns --image=busybox:1.36 --restart=Never -- sleep 3600

# Wait for pod to be ready
kubectl wait --for=condition=Ready pod/test-pod -n isolated-ns --timeout=30s

# Test egress (outbound) - should timeout/fail
kubectl exec test-pod -n isolated-ns -- wget --timeout=3 -O- http://google.com 2>&1 | tee /opt/course/01/test-output.txt

# Test DNS (also blocked by egress deny)
kubectl exec test-pod -n isolated-ns -- nslookup kubernetes.default 2>&1 | tee -a /opt/course/01/test-output.txt

# Expected output: connection timeouts or "bad address" errors
EOF

echo ""
echo "Step 4: Document blocked traffic"
echo ""

cat << 'EOF'
# Add documentation to test-output.txt
cat >> /opt/course/01/test-output.txt << 'DOC'

=== Traffic Blocked by default-deny-all NetworkPolicy ===

INGRESS (blocked):
- All incoming traffic from any pod in any namespace
- All incoming traffic from external sources
- All incoming traffic on any port/protocol

EGRESS (blocked):
- All outgoing traffic to any pod in any namespace
- All outgoing traffic to external services (internet)
- All DNS queries (port 53) - pods cannot resolve hostnames
- All outgoing traffic on any port/protocol

This implements zero-trust networking where all traffic must be explicitly allowed.
DOC
EOF

echo ""
echo "Key Points:"
echo "- podSelector: {} selects ALL pods in the namespace"
echo "- policyTypes lists which traffic directions are affected"
echo "- Omitting ingress/egress rules blocks all traffic of that type"
echo "- This is the foundation for zero-trust networking"
echo "- DNS is also blocked by egress deny (uses port 53)"
