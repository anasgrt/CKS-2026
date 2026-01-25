#!/bin/bash
# Verify Question 02 - NetworkPolicy Allow Specific Traffic

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "=============================================="
echo "Checking NetworkPolicy 'api-policy' in namespace 'microservices-ns'..."
echo "=============================================="

# Check if api-policy NetworkPolicy exists
if ! kubectl get networkpolicy api-policy -n microservices-ns &>/dev/null; then
    echo -e "${RED}✗ NetworkPolicy 'api-policy' not found${NC}"
    PASS=false
else
    echo -e "${GREEN}✓ NetworkPolicy 'api-policy' exists${NC}"

    # Get the full policy for analysis
    API_POLICY=$(kubectl get networkpolicy api-policy -n microservices-ns -o json)

    # Check podSelector targets tier=api
    TIER=$(echo "$API_POLICY" | jq -r '.spec.podSelector.matchLabels.tier // empty')
    if [ "$TIER" == "api" ]; then
        echo -e "${GREEN}✓ podSelector targets tier=api${NC}"
    else
        echo -e "${RED}✗ podSelector should target tier=api${NC}"
        PASS=false
    fi

    # Check policyTypes include Ingress and Egress
    POLICY_TYPES=$(echo "$API_POLICY" | jq -r '.spec.policyTypes[]?' | tr '\n' ' ')
    if [[ "$POLICY_TYPES" == *"Ingress"* ]] && [[ "$POLICY_TYPES" == *"Egress"* ]]; then
        echo -e "${GREEN}✓ policyTypes includes both Ingress and Egress${NC}"
    else
        echo -e "${RED}✗ policyTypes should include both Ingress and Egress${NC}"
        PASS=false
    fi

    # Check ingress from frontend on port 8080
    echo ""
    echo "Checking api-policy ingress rules..."

    INGRESS_FRONTEND=$(echo "$API_POLICY" | jq -r '
        .spec.ingress[]? |
        select(.from[]?.podSelector.matchLabels.tier == "frontend") |
        select(.ports[]?.port == 8080) |
        "found"' | head -1)
    if [ "$INGRESS_FRONTEND" == "found" ]; then
        echo -e "${GREEN}✓ Ingress allows from tier=frontend on port 8080${NC}"
    else
        echo -e "${RED}✗ Ingress should allow from tier=frontend on port 8080${NC}"
        PASS=false
    fi

    # Check ingress from monitoring-ns namespace
    INGRESS_MONITORING=$(echo "$API_POLICY" | jq -r '
        .spec.ingress[]?.from[]?.namespaceSelector.matchLabels // empty |
        select(. != null) |
        to_entries[] |
        select(.key == "kubernetes.io/metadata.name" or .key == "name") |
        select(.value == "monitoring-ns") |
        "found"' 2>/dev/null | head -1)
    if [ "$INGRESS_MONITORING" == "found" ]; then
        echo -e "${GREEN}✓ Ingress allows from namespace 'monitoring-ns'${NC}"
    else
        echo -e "${RED}✗ Ingress should allow from namespace 'monitoring-ns'${NC}"
        PASS=false
    fi

    # Check egress to database on port 5432
    echo ""
    echo "Checking api-policy egress rules..."

    EGRESS_DB=$(echo "$API_POLICY" | jq -r '
        .spec.egress[]? |
        select(.to[]?.podSelector.matchLabels.tier == "database") |
        select(.ports[]?.port == 5432) |
        "found"' | head -1)
    if [ "$EGRESS_DB" == "found" ]; then
        echo -e "${GREEN}✓ Egress allows to tier=database on port 5432${NC}"
    else
        echo -e "${RED}✗ Egress should allow to tier=database on port 5432${NC}"
        PASS=false
    fi

    # Check egress allows DNS (port 53 UDP)
    EGRESS_DNS=$(echo "$API_POLICY" | jq -r '
        .spec.egress[]? |
        select(.ports[]?.port == 53) |
        "found"' | head -1)
    if [ "$EGRESS_DNS" == "found" ]; then
        echo -e "${GREEN}✓ Egress allows DNS traffic (port 53)${NC}"
    else
        echo -e "${RED}✗ Egress should allow DNS traffic (port 53)${NC}"
        PASS=false
    fi
fi

echo ""
echo "=============================================="
echo "Checking NetworkPolicy 'database-policy' in namespace 'microservices-ns'..."
echo "=============================================="

# Check if database-policy NetworkPolicy exists
if ! kubectl get networkpolicy database-policy -n microservices-ns &>/dev/null; then
    echo -e "${RED}✗ NetworkPolicy 'database-policy' not found${NC}"
    PASS=false
else
    echo -e "${GREEN}✓ NetworkPolicy 'database-policy' exists${NC}"

    # Get the full policy for analysis
    DB_POLICY=$(kubectl get networkpolicy database-policy -n microservices-ns -o json)

    # Check podSelector targets tier=database
    TIER=$(echo "$DB_POLICY" | jq -r '.spec.podSelector.matchLabels.tier // empty')
    if [ "$TIER" == "database" ]; then
        echo -e "${GREEN}✓ podSelector targets tier=database${NC}"
    else
        echo -e "${RED}✗ podSelector should target tier=database${NC}"
        PASS=false
    fi

    # Check policyTypes include Ingress and Egress
    POLICY_TYPES=$(echo "$DB_POLICY" | jq -r '.spec.policyTypes[]?' | tr '\n' ' ')
    if [[ "$POLICY_TYPES" == *"Ingress"* ]] && [[ "$POLICY_TYPES" == *"Egress"* ]]; then
        echo -e "${GREEN}✓ policyTypes includes both Ingress and Egress${NC}"
    else
        echo -e "${RED}✗ policyTypes should include both Ingress and Egress${NC}"
        PASS=false
    fi

    # Check ingress from API pods on port 5432
    echo ""
    echo "Checking database-policy ingress rules..."

    INGRESS_API=$(echo "$DB_POLICY" | jq -r '
        .spec.ingress[]? |
        select(.from[]?.podSelector.matchLabels.tier == "api") |
        select(.ports[]?.port == 5432) |
        "found"' | head -1)
    if [ "$INGRESS_API" == "found" ]; then
        echo -e "${GREEN}✓ Ingress allows from tier=api on port 5432${NC}"
    else
        echo -e "${RED}✗ Ingress should allow from tier=api on port 5432${NC}"
        PASS=false
    fi

    # Check that ingress only allows from api (no other sources)
    INGRESS_SOURCES=$(echo "$DB_POLICY" | jq -r '.spec.ingress[]?.from[]?.podSelector.matchLabels.tier // empty' | sort -u)
    if [ "$INGRESS_SOURCES" == "api" ]; then
        echo -e "${GREEN}✓ Ingress only allows from tier=api (no other sources)${NC}"
    else
        echo -e "${RED}✗ Ingress should only allow from tier=api${NC}"
        PASS=false
    fi

    # Check egress allows DNS only
    echo ""
    echo "Checking database-policy egress rules..."

    EGRESS_DNS=$(echo "$DB_POLICY" | jq -r '
        .spec.egress[]? |
        select(.ports[]?.port == 53) |
        "found"' | head -1)
    if [ "$EGRESS_DNS" == "found" ]; then
        echo -e "${GREEN}✓ Egress allows DNS traffic (port 53)${NC}"
    else
        echo -e "${RED}✗ Egress should allow DNS traffic (port 53)${NC}"
        PASS=false
    fi

    # Check that egress is restricted (only DNS, no broad egress)
    EGRESS_COUNT=$(echo "$DB_POLICY" | jq '.spec.egress | length')
    EGRESS_PORTS=$(echo "$DB_POLICY" | jq -r '.spec.egress[]?.ports[]?.port // empty' | sort -u)
    if [ "$EGRESS_COUNT" == "1" ] && [ "$EGRESS_PORTS" == "53" ]; then
        echo -e "${GREEN}✓ Egress is restricted to DNS only${NC}"
    else
        echo -e "${RED}✗ Egress should be restricted to DNS only (port 53)${NC}"
        PASS=false
    fi
fi

# Check output files
echo ""
echo "=============================================="
echo "Checking output files..."
echo "=============================================="

if [ -f "/opt/course/02/api-netpol.yaml" ]; then
    echo -e "${GREEN}✓ /opt/course/02/api-netpol.yaml exists${NC}"
else
    echo -e "${RED}✗ /opt/course/02/api-netpol.yaml not found${NC}"
    PASS=false
fi

if [ -f "/opt/course/02/db-netpol.yaml" ]; then
    echo -e "${GREEN}✓ /opt/course/02/db-netpol.yaml exists${NC}"
else
    echo -e "${RED}✗ /opt/course/02/db-netpol.yaml not found${NC}"
    PASS=false
fi

if [ -f "/opt/course/02/connectivity-test.txt" ]; then
    echo -e "${GREEN}✓ /opt/course/02/connectivity-test.txt exists${NC}"
else
    echo -e "${RED}✗ /opt/course/02/connectivity-test.txt not found${NC}"
    PASS=false
fi

echo ""
echo "=============================================="
echo "Summary"
echo "=============================================="

if $PASS; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed${NC}"
    exit 1
fi
