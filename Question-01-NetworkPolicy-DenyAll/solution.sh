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
echo "Key Points:"
echo "- podSelector: {} selects ALL pods in the namespace"
echo "- policyTypes lists which traffic directions are affected"
echo "- Omitting ingress/egress rules blocks all traffic of that type"
echo "- This is the foundation for zero-trust networking"
