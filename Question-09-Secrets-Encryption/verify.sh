#!/bin/bash
# Verify Question 09 - Secrets Encryption

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Secrets Encryption configuration..."
echo ""

# Check encryption config file exists
if [ -f "/opt/course/09/encryption-config.yaml" ]; then
    echo -e "${GREEN}✓ EncryptionConfiguration file exists${NC}"

    # Check for aescbc provider
    if grep -q "aescbc" /opt/course/09/encryption-config.yaml; then
        echo -e "${GREEN}✓ Uses aescbc encryption provider${NC}"
    else
        echo -e "${RED}✗ Should use aescbc encryption provider${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ EncryptionConfiguration not found at /opt/course/09/encryption-config.yaml${NC}"
    PASS=false
fi

# Check namespace exists
if kubectl get namespace secrets-ns &>/dev/null; then
    echo -e "${GREEN}✓ Namespace 'secrets-ns' exists${NC}"
else
    echo -e "${RED}✗ Namespace 'secrets-ns' not found${NC}"
    PASS=false
fi

# Check secret exists
if kubectl get secret test-secret -n secrets-ns &>/dev/null; then
    echo -e "${GREEN}✓ Secret 'test-secret' exists${NC}"

    # Check secret has correct value (as per solution.sh)
    PASSWORD=$(kubectl get secret test-secret -n secrets-ns -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null)
    if [ "$PASSWORD" == "supersecret" ]; then
        echo -e "${GREEN}✓ Secret contains correct password value${NC}"
    else
        echo -e "${RED}✗ Secret should have password=supersecret (as per solution)${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Secret 'test-secret' not found${NC}"
    PASS=false
fi

# Check verification file
if [ -f "/opt/course/09/verification.txt" ]; then
    echo -e "${GREEN}✓ Verification output saved${NC}"
else
    echo -e "${YELLOW}⚠ Verification file not found at /opt/course/09/verification.txt${NC}"
    PASS=false
fi

# Check API server has encryption config (if we can access the manifest)
if [ -f "/etc/kubernetes/manifests/kube-apiserver.yaml" ]; then
    if grep -q "encryption-provider-config" /etc/kubernetes/manifests/kube-apiserver.yaml; then
        echo -e "${GREEN}✓ API server configured with encryption provider${NC}"
    else
        echo -e "${RED}✗ API server should have --encryption-provider-config flag${NC}"
        PASS=false
    fi
else
    echo -e "${YELLOW}⚠ Cannot verify API server config (not on control plane)${NC}"
fi

if $PASS; then
    exit 0
else
    exit 1
fi
