#!/bin/bash
# Verify Question 03 - CIS Benchmark

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking CIS Benchmark fixes..."
echo ""

# Check if kube-bench output exists
if [ -f "/opt/course/03/kube-bench-before.txt" ]; then
    echo -e "${GREEN}✓ kube-bench output saved${NC}"
else
    echo -e "${RED}✗ kube-bench output not found at /opt/course/03/kube-bench-before.txt${NC}"
    PASS=false
fi

# Check if fixes.txt exists
if [ -f "/opt/course/03/fixes.txt" ]; then
    echo -e "${GREEN}✓ fixes.txt found${NC}"
else
    echo -e "${RED}✗ fixes.txt not found at /opt/course/03/fixes.txt${NC}"
    PASS=false
fi

# Check API server configuration
echo ""
echo "Checking API server configuration..."

# Note: This simulates checking - in real exam you'd check the actual API server
API_SERVER_MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"

if [ -f "$API_SERVER_MANIFEST" ]; then
    # Check anonymous-auth
    if grep -q "\-\-anonymous-auth=false" "$API_SERVER_MANIFEST"; then
        echo -e "${GREEN}✓ anonymous-auth=false is set${NC}"
    else
        echo -e "${RED}✗ anonymous-auth should be set to false${NC}"
        PASS=false
    fi
    
    # Check authorization-mode includes RBAC
    if grep -q "\-\-authorization-mode=.*RBAC" "$API_SERVER_MANIFEST"; then
        echo -e "${GREEN}✓ authorization-mode includes RBAC${NC}"
    else
        echo -e "${RED}✗ authorization-mode should include RBAC${NC}"
        PASS=false
    fi
    
    # Check profiling is disabled
    if grep -q "\-\-profiling=false" "$API_SERVER_MANIFEST"; then
        echo -e "${GREEN}✓ profiling=false is set${NC}"
    else
        echo -e "${RED}✗ profiling should be set to false${NC}"
        PASS=false
    fi
else
    echo -e "${YELLOW}⚠ Cannot verify API server manifest (not running on control plane)${NC}"
    echo -e "${YELLOW}  Make sure you've made the changes on the control plane node${NC}"
fi

if $PASS; then
    exit 0
else
    exit 1
fi
