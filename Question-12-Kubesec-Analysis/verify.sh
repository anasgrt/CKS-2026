#!/bin/bash
# Verify Question 12 - Kubesec Analysis

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Kubesec analysis..."
echo ""

# Check kubesec report
if [ -f "/opt/course/12/kubesec-report.json" ]; then
    echo -e "${GREEN}✓ Kubesec report saved${NC}"
else
    echo -e "${RED}✗ Kubesec report not found${NC}"
    PASS=false
fi

# Check secure deployment file
if [ -f "/opt/course/12/secure-deploy.yaml" ]; then
    echo -e "${GREEN}✓ Secure deployment file exists${NC}"
    
    # Check no privileged
    if ! grep -q "privileged: true" /opt/course/12/secure-deploy.yaml; then
        echo -e "${GREEN}✓ No privileged: true${NC}"
    else
        echo -e "${RED}✗ Should not have privileged: true${NC}"
        PASS=false
    fi
    
    # Check for runAsNonRoot or runAsUser
    if grep -q "runAsNonRoot: true\|runAsUser:" /opt/course/12/secure-deploy.yaml; then
        echo -e "${GREEN}✓ Has runAsNonRoot or runAsUser${NC}"
    else
        echo -e "${YELLOW}⚠ Consider adding runAsNonRoot: true${NC}"
    fi
    
    # Check for readOnlyRootFilesystem
    if grep -q "readOnlyRootFilesystem: true" /opt/course/12/secure-deploy.yaml; then
        echo -e "${GREEN}✓ Has readOnlyRootFilesystem: true${NC}"
    else
        echo -e "${YELLOW}⚠ Consider adding readOnlyRootFilesystem: true${NC}"
    fi
    
    # Check for capability drop
    if grep -q "drop:" /opt/course/12/secure-deploy.yaml; then
        echo -e "${GREEN}✓ Has capabilities drop${NC}"
    else
        echo -e "${YELLOW}⚠ Consider dropping capabilities${NC}"
    fi
else
    echo -e "${RED}✗ Secure deployment not found${NC}"
    PASS=false
fi

# Check kubesec-fixed.json (question requirement)
echo ""
echo "Checking fixed deployment scan..."
if [ -f "/opt/course/12/kubesec-fixed.json" ]; then
    echo -e "${GREEN}✓ kubesec-fixed.json saved${NC}"

    # Check score >= 8 (question requirement)
    SCORE=$(jq -r '.[0].score // 0' /opt/course/12/kubesec-fixed.json 2>/dev/null)
    if [ -n "$SCORE" ] && [ "$SCORE" -ge 8 ] 2>/dev/null; then
        echo -e "${GREEN}✓ Kubesec score is $SCORE (>= 8 required)${NC}"
    else
        echo -e "${RED}✗ Kubesec score should be >= 8 (current: $SCORE)${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ kubesec-fixed.json not found at /opt/course/12/kubesec-fixed.json${NC}"
    PASS=false
fi

# Check deployment is running
echo ""
if kubectl get deployment web-app -n kubesec-ns &>/dev/null; then
    echo -e "${GREEN}✓ Deployment 'web-app' exists in cluster${NC}"
else
    echo -e "${RED}✗ Deployment 'web-app' not found in kubesec-ns${NC}"
    PASS=false
fi

if $PASS; then
    exit 0
else
    exit 1
fi
