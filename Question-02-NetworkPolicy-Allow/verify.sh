#!/bin/bash
# Verify Question 02 - NetworkPolicy Allow Specific Traffic

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking NetworkPolicy 'api-policy' in namespace 'microservices-ns'..."

# Check if api-policy NetworkPolicy exists
if ! kubectl get networkpolicy api-policy -n microservices-ns &>/dev/null; then
    echo -e "${RED}✗ NetworkPolicy 'api-policy' not found${NC}"
    PASS=false
else
    echo -e "${GREEN}✓ NetworkPolicy 'api-policy' exists${NC}"

    # Check podSelector targets tier=api
    TIER=$(kubectl get networkpolicy api-policy -n microservices-ns -o jsonpath='{.spec.podSelector.matchLabels.tier}')
    if [ "$TIER" == "api" ]; then
        echo -e "${GREEN}✓ podSelector targets tier=api${NC}"
    else
        echo -e "${RED}✗ podSelector should target tier=api${NC}"
        PASS=false
    fi
fi

echo ""
echo "Checking NetworkPolicy 'database-policy' in namespace 'microservices-ns'..."

# Check if database-policy NetworkPolicy exists
if ! kubectl get networkpolicy database-policy -n microservices-ns &>/dev/null; then
    echo -e "${RED}✗ NetworkPolicy 'database-policy' not found${NC}"
    PASS=false
else
    echo -e "${GREEN}✓ NetworkPolicy 'database-policy' exists${NC}"

    # Check podSelector targets tier=database
    TIER=$(kubectl get networkpolicy database-policy -n microservices-ns -o jsonpath='{.spec.podSelector.matchLabels.tier}')
    if [ "$TIER" == "database" ]; then
        echo -e "${GREEN}✓ podSelector targets tier=database${NC}"
    else
        echo -e "${RED}✗ podSelector should target tier=database${NC}"
        PASS=false
    fi

    # Check ingress from tier=api on port 5432
    INGRESS_FROM=$(kubectl get networkpolicy database-policy -n microservices-ns -o jsonpath='{.spec.ingress[0].from[0].podSelector.matchLabels.tier}')
    if [ "$INGRESS_FROM" == "api" ]; then
        echo -e "${GREEN}✓ Ingress allows from tier=api${NC}"
    else
        echo -e "${RED}✗ Ingress should allow from tier=api${NC}"
        PASS=false
    fi
fi

# Check output files
echo ""
echo "Checking output files..."
if [ -f "/opt/course/02/api-netpol.yaml" ]; then
    echo -e "${GREEN}✓ api-netpol.yaml exists${NC}"
else
    echo -e "${RED}✗ api-netpol.yaml not found${NC}"
    PASS=false
fi

if [ -f "/opt/course/02/db-netpol.yaml" ]; then
    echo -e "${GREEN}✓ db-netpol.yaml exists${NC}"
else
    echo -e "${RED}✗ db-netpol.yaml not found${NC}"
    PASS=false
fi

if $PASS; then
    exit 0
else
    exit 1
fi
