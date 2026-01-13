#!/bin/bash
# Solution for Question 19 - Ingress TLS

echo "Solution: Configure TLS for Ingress"
echo ""
echo "Step 1: Create TLS Secret"
echo ""

cat << 'EOF'
kubectl create secret tls web-tls-secret \
  --cert=/opt/course/19/tls.crt \
  --key=/opt/course/19/tls.key \
  -n web-ns
EOF

echo ""
echo "Step 2: Create Ingress with TLS"
echo ""

cat << 'EOF'
cat > /opt/course/19/ingress.yaml << 'YAML'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
  namespace: web-ns
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - secure.example.com
      secretName: web-tls-secret
  rules:
    - host: secure.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-svc
                port:
                  number: 80
YAML

kubectl apply -f /opt/course/19/ingress.yaml
EOF

echo ""
echo "Step 3: Verify TLS"
echo ""

cat << 'EOF'
# Test HTTPS (add to /etc/hosts: <ingress-ip> secure.example.com)
curl -k https://secure.example.com

# Check certificate
openssl s_client -connect secure.example.com:443 -servername secure.example.com
EOF

echo ""
echo "Key Points:"
echo "- TLS secrets must be type 'kubernetes.io/tls'"
echo "- Certificate and key must be PEM encoded"
echo "- ssl-redirect annotation forces HTTPS"
echo "- Use cert-manager for automatic certificate management"
echo "- Multiple hosts can share one secret (SAN certificates)"
echo "- Always use TLS in production"
