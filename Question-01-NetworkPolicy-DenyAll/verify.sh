#!/bin/bash
# Verify Question 01 - NetworkPolicy Default Deny

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking NetworkPolicy 'default-deny-all' in namespace 'isolated-ns'..."

# Check if NetworkPolicy exists
if ! kubectl get networkpolicy default-deny-all -n isolated-ns &>/dev/null; then
    echo -e "${RED}✗ NetworkPolicy 'default-deny-all' not found in namespace 'isolated-ns'${NC}"
    PASS=false
else
    echo -e "${GREEN}✓ NetworkPolicy exists${NC}"

    # Check podSelector is empty (selects all pods)
    POD_SELECTOR=$(kubectl get networkpolicy default-deny-all -n isolated-ns -o jsonpath='{.spec.podSelector}')
    if [ "$POD_SELECTOR" == "{}" ]; then
        echo -e "${GREEN}✓ podSelector selects all pods${NC}"
    else
        echo -e "${RED}✗ podSelector should be empty to select all pods${NC}"
        PASS=false
    fi

    # Check policyTypes include Ingress
    INGRESS=$(kubectl get networkpolicy default-deny-all -n isolated-ns -o jsonpath='{.spec.policyTypes}' | grep -c Ingress || true)
    if [ "$INGRESS" -ge 1 ]; then
        echo -e "${GREEN}✓ Policy includes Ingress type${NC}"
    else
        echo -e "${RED}✗ Policy must include Ingress in policyTypes${NC}"
        PASS=false
    fi

    # Check policyTypes include Egress
    EGRESS=$(kubectl get networkpolicy default-deny-all -n isolated-ns -o jsonpath='{.spec.policyTypes}' | grep -c Egress || true)
    if [ "$EGRESS" -ge 1 ]; then
        echo -e "${GREEN}✓ Policy includes Egress type${NC}"
    else
        echo -e "${RED}✗ Policy must include Egress in policyTypes${NC}"
        PASS=false
    fi

    # Check no ingress rules (deny all)
    INGRESS_RULES=$(kubectl get networkpolicy default-deny-all -n isolated-ns -o jsonpath='{.spec.ingress}')
    if [ -z "$INGRESS_RULES" ] || [ "$INGRESS_RULES" == "null" ]; then
        echo -e "${GREEN}✓ No ingress rules (denies all ingress)${NC}"
    else
        echo -e "${RED}✗ Should have no ingress rules to deny all ingress${NC}"
        PASS=false
    fi

    # Check no egress rules (deny all)
    EGRESS_RULES=$(kubectl get networkpolicy default-deny-all -n isolated-ns -o jsonpath='{.spec.egress}')
    if [ -z "$EGRESS_RULES" ] || [ "$EGRESS_RULES" == "null" ]; then
        echo -e "${GREEN}✓ No egress rules (denies all egress)${NC}"
    else
        echo -e "${RED}✗ Should have no egress rules to deny all egress${NC}"
        PASS=false
    fi
fi

if $PASS; then
    exit 0
else
    exit 1
fi
