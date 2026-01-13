#!/bin/bash
# Verify Question 18 - Node Metadata Protection

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking metadata protection..."
echo ""

# Check namespace
if kubectl get namespace protected-ns &>/dev/null; then
    echo -e "${GREEN}✓ Namespace 'protected-ns' exists${NC}"
else
    echo -e "${RED}✗ Namespace 'protected-ns' not found${NC}"
    PASS=false
fi

# Check NetworkPolicy file
if [ -f "/opt/course/18/metadata-netpol.yaml" ]; then
    echo -e "${GREEN}✓ NetworkPolicy file exists${NC}"

    # Check blocks metadata IP
    if grep -q "169.254.169.254" /opt/course/18/metadata-netpol.yaml; then
        echo -e "${GREEN}✓ Policy references metadata IP${NC}"
    else
        echo -e "${RED}✗ Policy should block 169.254.169.254${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ NetworkPolicy not found at /opt/course/18/metadata-netpol.yaml${NC}"
    PASS=false
fi

# Check NetworkPolicy exists in cluster
if kubectl get networkpolicy block-metadata -n protected-ns &>/dev/null; then
    echo -e "${GREEN}✓ NetworkPolicy 'block-metadata' applied to cluster${NC}"

    # Check it's an egress policy
    POLICY_TYPES=$(kubectl get networkpolicy block-metadata -n protected-ns -o jsonpath='{.spec.policyTypes}')
    if [[ "$POLICY_TYPES" == *"Egress"* ]]; then
        echo -e "${GREEN}✓ Policy includes Egress rules${NC}"
    else
        echo -e "${RED}✗ Policy should include Egress rules${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ NetworkPolicy 'block-metadata' not found in protected-ns${NC}"
    PASS=false
fi

# Check test result
if [ -f "/opt/course/18/test-result.txt" ]; then
    echo -e "${GREEN}✓ Test result saved${NC}"
else
    echo -e "${RED}✗ Test result not found at /opt/course/18/test-result.txt${NC}"
    PASS=false
fi

if $PASS; then
    exit 0
else
    exit 1
fi
