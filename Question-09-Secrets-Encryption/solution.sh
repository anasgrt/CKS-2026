#!/bin/bash
# Solution for Question 09 - Secrets Encryption

echo "=== Step 1: Generate Key and Create Config ==="
echo "head -c 32 /dev/urandom | base64"
echo ""
cat << 'EOF'
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
        secret: <YOUR_BASE64_KEY_HERE>
  - identity: {}
YAML

sudo cp /opt/course/09/encryption-config.yaml /etc/kubernetes/encryption-config.yaml
EOF

echo ""
echo "=== Step 2: Edit API Server ==="
echo "sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml"
cat << 'EOF'
# Add to command:
    - --encryption-provider-config=/etc/kubernetes/encryption-config.yaml

# Add volumeMount (pki volume already mounts /etc/kubernetes/pki, but we need /etc/kubernetes):
    - name: encryption-config
      mountPath: /etc/kubernetes/encryption-config.yaml
      readOnly: true

# Add volume:
  - name: encryption-config
    hostPath:
      path: /etc/kubernetes/encryption-config.yaml
      type: File
EOF

echo ""
echo "=== Step 3: Create Secret and Verify ==="
echo "kubectl create secret generic test-secret -n secrets-ns --from-literal=password=supersecret"
echo ""
echo "# Verify in etcd (look for 'k8s:enc:aescbc' prefix, NOT plain text):"
cat << 'EOF'
ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/secrets-ns/test-secret | hexdump -C > /opt/course/09/verification.txt
EOF
echo ""
echo "Key: identity: {} allows reading old unencrypted secrets. First provider encrypts new secrets."
