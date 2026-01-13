#!/bin/bash
# Verify Question 14 - Audit Logs

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking Audit configuration..."
echo ""

# Check audit policy file
if [ -f "/opt/course/14/audit-policy.yaml" ]; then
    echo -e "${GREEN}✓ Audit policy file exists${NC}"
    
    # Check secrets level
    if grep -A5 "secrets" /opt/course/14/audit-policy.yaml | grep -qi "RequestResponse"; then
        echo -e "${GREEN}✓ Secrets logged at RequestResponse level${NC}"
    else
        echo -e "${RED}✗ Secrets should be logged at RequestResponse level${NC}"
        PASS=false
    fi
    
    # Check configmaps level
    if grep -A5 "configmaps" /opt/course/14/audit-policy.yaml | grep -qi "Metadata"; then
        echo -e "${GREEN}✓ ConfigMaps logged at Metadata level${NC}"
    else
        echo -e "${RED}✗ ConfigMaps should be logged at Metadata level${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Audit policy not found at /opt/course/14/audit-policy.yaml${NC}"
    PASS=false
fi

# Check API server configuration (if accessible)
if [ -f "/etc/kubernetes/manifests/kube-apiserver.yaml" ]; then
    echo ""
    echo "Checking API server configuration..."
    
    if grep -q "audit-policy-file" /etc/kubernetes/manifests/kube-apiserver.yaml; then
        echo -e "${GREEN}✓ API server has audit-policy-file configured${NC}"
    else
        echo -e "${YELLOW}⚠ API server audit-policy-file not found${NC}"
    fi
    
    if grep -q "audit-log-path" /etc/kubernetes/manifests/kube-apiserver.yaml; then
        echo -e "${GREEN}✓ API server has audit-log-path configured${NC}"
    else
        echo -e "${YELLOW}⚠ API server audit-log-path not found${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot verify API server config (not on control plane)${NC}"
fi

# Check secret audit log
if [ -f "/opt/course/14/secret-audit.log" ]; then
    echo -e "${GREEN}✓ Secret audit log captured${NC}"
else
    echo -e "${RED}✗ Secret audit log not found${NC}"
    PASS=false
fi

if $PASS; then
    exit 0
else
    exit 1
fi
