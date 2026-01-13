#!/bin/bash
# Solution for Question 09 - Secrets Encryption

echo "Solution: Configure encryption at rest for Secrets"
echo ""
echo "Step 1: Generate encryption key"
echo ""
echo "head -c 32 /dev/urandom | base64"
echo "# Example output: aGVsbG93b3JsZGhlbGxvd29ybGRoZWxsb3dvcmxkaGVsbG8="
echo ""
echo "Step 2: Create EncryptionConfiguration"
echo ""

cat << 'EOF'
# On control plane node:
sudo mkdir -p /etc/kubernetes/enc

cat > /opt/course/09/encryption-config.yaml << 'YAML'
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: aGVsbG93b3JsZGhlbGxvd29ybGRoZWxsb3dvcmxkaGVsbG8=
      - identity: {}
YAML

# Copy to /etc/kubernetes/enc/
sudo cp /opt/course/09/encryption-config.yaml /etc/kubernetes/enc/
EOF

echo ""
echo "Step 3: Configure API server"
echo ""

cat << 'EOF'
# Edit /etc/kubernetes/manifests/kube-apiserver.yaml
# Add to command args:
    - --encryption-provider-config=/etc/kubernetes/enc/encryption-config.yaml

# Add volume mount:
    volumeMounts:
    - name: enc
      mountPath: /etc/kubernetes/enc
      readOnly: true

# Add volume:
    volumes:
    - name: enc
      hostPath:
        path: /etc/kubernetes/enc
        type: DirectoryOrCreate
EOF

echo ""
echo "Step 4: Create the secret"
echo ""
echo "kubectl create secret generic test-secret -n secrets-ns --from-literal=password=supersecret"
echo ""
echo "Step 5: Verify encryption in etcd"
echo ""

cat << 'EOF'
# Read secret directly from etcd:
ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/secrets-ns/test-secret | hexdump -C > /opt/course/09/verification.txt

# If encrypted, output should show 'k8s:enc:aescbc:v1:key1' prefix
# not plain text
EOF

echo ""
echo "Key Points:"
echo "- identity: {} provider allows reading existing unencrypted secrets"
echo "- Order matters: first provider is used for encryption"
echo "- After configuration change, re-encrypt existing secrets:"
echo "  kubectl get secrets -A -o json | kubectl replace -f -"
echo "- Always backup etcd before enabling encryption"
