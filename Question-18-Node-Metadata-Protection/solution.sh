#!/bin/bash
# Solution for Question 18 - Node Metadata Protection

echo "Solution: Block cloud metadata access"
echo ""
echo "Step 1: Create NetworkPolicy"
echo ""

cat << 'EOF'
cat > /opt/course/18/metadata-netpol.yaml << 'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-metadata
  namespace: protected-ns
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    # Allow DNS
    - to: []
      ports:
        - port: 53
          protocol: UDP
        - port: 53
          protocol: TCP
    # Allow all egress EXCEPT metadata IP
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
              - 169.254.169.254/32
YAML

kubectl apply -f /opt/course/18/metadata-netpol.yaml
EOF

echo ""
echo "Step 2: Create test pod"
echo ""

cat << 'EOF'
kubectl run test-metadata -n protected-ns --image=curlimages/curl --rm -it --restart=Never -- \
  curl -s --connect-timeout 3 http://169.254.169.254/latest/meta-data/ > /opt/course/18/test-result.txt 2>&1

# If NetworkPolicy works, you should see:
# "Connection timed out" or "Connection refused"
EOF

echo ""
echo "Alternative test:"
echo ""

cat << 'EOF'
# Create persistent test pod
kubectl run test-pod --image=curlimages/curl -n protected-ns -- sleep 3600

# Wait for pod
kubectl wait --for=condition=Ready pod/test-pod -n protected-ns

# Test metadata access
kubectl exec test-pod -n protected-ns -- curl -s --connect-timeout 3 http://169.254.169.254/latest/meta-data/

# Expected: connection timeout (blocked by NetworkPolicy)
EOF

echo ""
echo "Key Points:"
echo "- IMDS (Instance Metadata Service) can expose IAM credentials"
echo "- AWS IMDS allows role assumption if credentials leaked"
echo "- GCP metadata can expose service account tokens"
echo "- NetworkPolicy requires a CNI that supports it (Calico, Cilium)"
echo "- Consider also using IMDSv2 on AWS (requires hop limit)"
echo "- Block metadata in ALL namespaces for defense in depth"
