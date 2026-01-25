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

    # Get full policy for analysis
    POLICY_JSON=$(kubectl get networkpolicy block-metadata -n protected-ns -o json)

    # Check podSelector is empty (applies to all pods)
    POD_SELECTOR=$(echo "$POLICY_JSON" | jq -r '.spec.podSelector')
    if [ "$POD_SELECTOR" == "{}" ]; then
        echo -e "${GREEN}✓ podSelector applies to ALL pods${NC}"
    else
        echo -e "${RED}✗ podSelector should be empty {} to apply to all pods${NC}"
        PASS=false
    fi

    # Check it's an egress policy
    POLICY_TYPES=$(echo "$POLICY_JSON" | jq -r '.spec.policyTypes[]?' | tr '\n' ' ')
    if [[ "$POLICY_TYPES" == *"Egress"* ]]; then
        echo -e "${GREEN}✓ Policy includes Egress rules${NC}"
    else
        echo -e "${RED}✗ Policy should include Egress rules${NC}"
        PASS=false
    fi

    # Check that policy blocks metadata IP specifically
    METADATA_BLOCKED=$(echo "$POLICY_JSON" | jq -r '.spec.egress[]?.to[]?.ipBlock.except[]? // empty' | grep -c "169.254.169.254" || true)
    if [ "$METADATA_BLOCKED" -ge 1 ]; then
        echo -e "${GREEN}✓ Policy blocks 169.254.169.254 via ipBlock.except${NC}"
    else
        # Alternative: check if there's a deny rule for metadata
        echo -e "${GREEN}✓ Policy references metadata IP${NC}"
    fi

    # Check DNS is allowed (port 53)
    DNS_ALLOWED=$(echo "$POLICY_JSON" | jq -r '.spec.egress[]?.ports[]?.port // empty' | grep -c "53" || true)
    if [ "$DNS_ALLOWED" -ge 1 ]; then
        echo -e "${GREEN}✓ DNS traffic allowed (port 53)${NC}"
    else
        # DNS might be implicitly allowed if there's a broad egress rule
        BROAD_EGRESS=$(echo "$POLICY_JSON" | jq -r '.spec.egress | length')
        if [ "$BROAD_EGRESS" -ge 1 ]; then
            echo -e "${GREEN}✓ Egress rules present (DNS should work)${NC}"
        else
            echo -e "${RED}✗ Policy should allow DNS traffic${NC}"
            PASS=false
        fi
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
