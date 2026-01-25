#!/bin/bash
# Solution for Question 17 - Binary Verification

echo "=== Step 1: Download Official Checksum ==="
echo "# Get kubectl version first"
echo "kubectl version --client"
echo ""
echo "# Download checksum for that version (example v1.30.0)"
echo "curl -LO https://dl.k8s.io/v1.30.0/bin/linux/amd64/kubectl.sha512"
echo ""

echo "=== Step 2: Verify kubectl ==="
cat << 'EOF'
# Compare checksums
echo "$(cat kubectl.sha512)  /usr/local/bin/kubectl" | sha512sum -c

# Save result
sha512sum /usr/local/bin/kubectl > /opt/course/17/kubectl-verify.txt
cat kubectl.sha512 >> /opt/course/17/kubectl-verify.txt
EOF
echo ""

echo "=== Step 3: Verify Suspicious kubelet ==="
cat << 'EOF'
curl -LO https://dl.k8s.io/v1.30.0/bin/linux/amd64/kubelet.sha512

# Compare
EXPECTED=$(cat kubelet.sha512)
ACTUAL=$(sha512sum /tmp/kubelet-suspicious | awk '{print $1}')

echo "Expected: $EXPECTED" > /opt/course/17/kubelet-verify.txt
echo "Actual:   $ACTUAL" >> /opt/course/17/kubelet-verify.txt

if [ "$EXPECTED" == "$ACTUAL" ]; then
    echo "GENUINE" >> /opt/course/17/kubelet-verify.txt
else
    echo "TAMPERED" >> /opt/course/17/kubelet-verify.txt
fi
EOF
echo ""

echo "=== Step 4: Write Conclusion ==="
echo "echo 'TAMPERED' > /opt/course/17/conclusion.txt"
echo ""
echo "Key: Official checksums at dl.k8s.io/<version>/bin/linux/<arch>/<binary>.sha512"
