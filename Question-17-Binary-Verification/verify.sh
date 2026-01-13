#!/bin/bash
# Verify Question 17 - Binary Verification

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking binary verification..."
echo ""

# Check kubectl verification
if [ -f "/opt/course/17/kubectl-verify.txt" ]; then
    echo -e "${GREEN}✓ kubectl verification saved${NC}"
else
    echo -e "${RED}✗ kubectl verification not found${NC}"
    PASS=false
fi

# Check kubelet verification
if [ -f "/opt/course/17/kubelet-verify.txt" ]; then
    echo -e "${GREEN}✓ kubelet verification saved${NC}"
else
    echo -e "${RED}✗ kubelet verification not found${NC}"
    PASS=false
fi

# Check conclusion
if [ -f "/opt/course/17/conclusion.txt" ]; then
    echo -e "${GREEN}✓ Conclusion file exists${NC}"
    
    CONCLUSION=$(cat /opt/course/17/conclusion.txt | tr '[:lower:]' '[:upper:]')
    if [[ "$CONCLUSION" == *"TAMPERED"* ]]; then
        echo -e "${GREEN}✓ Correctly identified as TAMPERED${NC}"
    else
        echo -e "${RED}✗ The suspicious binary should be identified as TAMPERED${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Conclusion not found${NC}"
    PASS=false
fi

if $PASS; then
    exit 0
else
    exit 1
fi
