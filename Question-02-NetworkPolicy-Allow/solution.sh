#!/bin/bash
# Solution for Question 02 - NetworkPolicy Allow Specific Traffic

echo "Solution: Create NetworkPolicies for microservices architecture"
echo ""
echo "Step 1: Create API NetworkPolicy YAML file"
echo ""

cat << 'EOF'
cat > /opt/course/02/api-netpol.yaml << 'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-policy
  namespace: microservices-ns
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    # Allow from frontend pods
    - from:
        - podSelector:
            matchLabels:
              tier: frontend
      ports:
        - protocol: TCP
          port: 8080
    # Allow from monitoring namespace
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring-ns
      ports:
        - protocol: TCP
          port: 8080
  egress:
    # Allow DNS
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
    # Allow database access
    - to:
        - podSelector:
            matchLabels:
              tier: database
      ports:
        - protocol: TCP
          port: 5432
YAML

kubectl apply -f /opt/course/02/api-netpol.yaml
EOF

echo ""
echo "Step 2: Create Database NetworkPolicy YAML file"
echo ""

cat << 'EOF'
cat > /opt/course/02/db-netpol.yaml << 'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
  namespace: microservices-ns
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
    - Ingress
    - Egress
  ingress:
    # Only allow from API pods
    - from:
        - podSelector:
            matchLabels:
              tier: api
      ports:
        - protocol: TCP
          port: 5432
  egress:
    # Only allow DNS
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
YAML

kubectl apply -f /opt/course/02/db-netpol.yaml
EOF

echo ""
echo "Step 3: Test connectivity"
echo ""
echo "# Frontend -> Database should be BLOCKED:"
echo "kubectl exec -n microservices-ns frontend -- curl -s --connect-timeout 2 database:5432"
echo ""
echo "# API -> Database should WORK:"
echo "kubectl exec -n microservices-ns api -- curl -s --connect-timeout 2 database:5432"
echo ""
echo "Key Points:"
echo "- Use podSelector to target specific pods"
echo "- ingress.from defines allowed sources"
echo "- egress.to defines allowed destinations"
echo "- Always allow DNS (port 53) for name resolution"
echo "- namespaceSelector can allow cross-namespace traffic"
