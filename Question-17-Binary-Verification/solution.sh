#!/bin/bash
# Solution for Question 17 - Binary Verification

echo "Solution: Verify Kubernetes binary integrity"
echo ""
echo "Step 1: Download official kubectl checksum"
echo ""

cat << 'EOF'
curl -LO https://dl.k8s.io/v1.30.0/bin/linux/amd64/kubectl.sha512

# Or for the exact kubectl version on your system:
KUBECTL_VERSION=$(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')
curl -LO "https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha512"
EOF

echo ""
echo "Step 2: Verify kubectl"
echo ""

cat << 'EOF'
# Method 1: Compare checksums manually
EXPECTED=$(cat kubectl.sha512 | awk '{print $1}')
ACTUAL=$(sha512sum /usr/local/bin/kubectl | awk '{print $1}')

if [ "$EXPECTED" == "$ACTUAL" ]; then
    echo "kubectl: CHECKSUM VERIFIED" > /opt/course/17/kubectl-verify.txt
else
    echo "kubectl: CHECKSUM MISMATCH" > /opt/course/17/kubectl-verify.txt
fi

# Method 2: Use sha512sum -c
echo "$(cat kubectl.sha512 | awk '{print $1}')  /usr/local/bin/kubectl" | sha512sum -c
EOF

echo ""
echo "Step 3: Download kubelet checksum and verify suspicious binary"
echo ""

cat << 'EOF'
curl -LO https://dl.k8s.io/v1.30.0/bin/linux/amd64/kubelet.sha512

EXPECTED=$(cat kubelet.sha512 | awk '{print $1}')
ACTUAL=$(sha512sum /tmp/kubelet | awk '{print $1}')

echo "Expected: $EXPECTED" > /opt/course/17/kubelet-verify.txt
echo "Actual:   $ACTUAL" >> /opt/course/17/kubelet-verify.txt

if [ "$EXPECTED" == "$ACTUAL" ]; then
    echo "MATCH: Binary is genuine" >> /opt/course/17/kubelet-verify.txt
else
    echo "MISMATCH: Binary may be tampered" >> /opt/course/17/kubelet-verify.txt
fi
EOF

echo ""
echo "Step 4: Write conclusion"
echo ""

cat << 'EOF'
# Since /tmp/kubelet is a fake file, it won't match
echo "TAMPERED" > /opt/course/17/conclusion.txt
EOF

echo ""
echo "Key Points:"
echo "- Always verify binaries from official sources"
echo "- Checksums available at dl.k8s.io for all versions"
echo "- sha512sum is preferred over sha256sum or md5sum"
echo "- Also verify downloaded YAML manifests"
echo "- Use cosign for signed artifact verification"
