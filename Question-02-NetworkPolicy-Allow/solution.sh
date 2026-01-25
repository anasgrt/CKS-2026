#!/bin/bash
# Solution for Question 02 - NetworkPolicy Allow Specific Traffic

echo "=== API Pod Policy (from frontend + monitoring, to database + DNS) ==="
cat << 'EOF'
cat <<YAML | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-policy
  namespace: microservices-ns
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes: [Ingress, Egress]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - port: 8080
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring-ns
    ports:
    - port: 8080
  egress:
  - to:  # DNS
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - port: 53
      protocol: UDP
  - to:  # Database
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - port: 5432
YAML
EOF

echo ""
echo "=== Database Pod Policy (from api only, DNS egress) ==="
cat << 'EOF'
cat <<YAML | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
  namespace: microservices-ns
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes: [Ingress, Egress]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: api
    ports:
    - port: 5432
  egress:
  - to:  # DNS only
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - port: 53
      protocol: UDP
YAML
EOF

echo ""
echo "# Save files"
echo "kubectl get netpol api-policy -n microservices-ns -o yaml > /opt/course/02/api-netpol.yaml"
echo "kubectl get netpol database-policy -n microservices-ns -o yaml > /opt/course/02/db-netpol.yaml"
echo ""
echo "Key: podSelector=who this applies to, ingress.from=allowed sources, egress.to=allowed destinations"
