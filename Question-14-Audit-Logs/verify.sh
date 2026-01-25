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

    echo ""
    echo "Checking audit policy rules..."

    # Rule 1: Check secrets at RequestResponse level
    if grep -B2 -A5 'resources:.*secrets' /opt/course/14/audit-policy.yaml | grep -q "level: RequestResponse"; then
        echo -e "${GREEN}✓ Secrets logged at RequestResponse level${NC}"
    else
        echo -e "${RED}✗ Secrets should be logged at RequestResponse level${NC}"
        PASS=false
    fi

    # Rule 2: Check pods and pods/log at Metadata level
    if grep -B2 -A5 'pods/log\|pods.*pods/log' /opt/course/14/audit-policy.yaml | grep -q "level: Metadata"; then
        echo -e "${GREEN}✓ pods/log logged at Metadata level${NC}"
    else
        echo -e "${RED}✗ pods and pods/log should be logged at Metadata level${NC}"
        PASS=false
    fi

    # Rule 3: Check controller-leader configmap exclusion
    if grep -q "controller-leader" /opt/course/14/audit-policy.yaml; then
        if grep -B5 "controller-leader" /opt/course/14/audit-policy.yaml | grep -q "level: None"; then
            echo -e "${GREEN}✓ controller-leader configmap excluded (level: None)${NC}"
        else
            echo -e "${RED}✗ controller-leader configmap should have level: None${NC}"
            PASS=false
        fi
    else
        echo -e "${RED}✗ Missing rule for controller-leader configmap exclusion${NC}"
        PASS=false
    fi

    # Rule 4: Check kube-proxy watch exclusion
    if grep -q "system:kube-proxy" /opt/course/14/audit-policy.yaml; then
        if grep -B5 -A5 "system:kube-proxy" /opt/course/14/audit-policy.yaml | grep -q "watch"; then
            echo -e "${GREEN}✓ kube-proxy watch requests excluded${NC}"
        else
            echo -e "${YELLOW}⚠ kube-proxy rule found but may not exclude watch requests${NC}"
        fi
    else
        echo -e "${RED}✗ Missing rule for kube-proxy watch exclusion${NC}"
        PASS=false
    fi

    # Rule 5: Check kube-system configmap/secret changes at Request level
    if grep -q "kube-system" /opt/course/14/audit-policy.yaml; then
        if grep -B5 -A10 "kube-system" /opt/course/14/audit-policy.yaml | grep -q "level: Request"; then
            echo -e "${GREEN}✓ kube-system changes logged at Request level${NC}"
        else
            echo -e "${YELLOW}⚠ kube-system rule found but may not be at Request level${NC}"
        fi
    else
        echo -e "${RED}✗ Missing rule for kube-system namespace changes${NC}"
        PASS=false
    fi

    # Rule 6: Check catch-all rule
    # A catch-all rule is typically "level: Metadata" without specific resources
    LAST_RULE=$(tail -5 /opt/course/14/audit-policy.yaml | grep -c "level: Metadata")
    if [ "$LAST_RULE" -ge 1 ]; then
        echo -e "${GREEN}✓ Catch-all rule at Metadata level present${NC}"
    else
        echo -e "${YELLOW}⚠ Catch-all rule may be missing or not at Metadata level${NC}"
    fi

else
    echo -e "${RED}✗ Audit policy not found at /opt/course/14/audit-policy.yaml${NC}"
    PASS=false
fi

# Check API server configuration (if accessible)
echo ""
echo "Checking API server configuration..."

API_SERVER_MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"

if [ -f "$API_SERVER_MANIFEST" ]; then
    if grep -q "audit-policy-file" "$API_SERVER_MANIFEST"; then
        echo -e "${GREEN}✓ API server has audit-policy-file configured${NC}"
    else
        echo -e "${RED}✗ API server missing --audit-policy-file flag${NC}"
        PASS=false
    fi

    if grep -q "audit-log-path" "$API_SERVER_MANIFEST"; then
        echo -e "${GREEN}✓ API server has audit-log-path configured${NC}"
    else
        echo -e "${RED}✗ API server missing --audit-log-path flag${NC}"
        PASS=false
    fi

    if grep -q "audit-log-maxage=8" "$API_SERVER_MANIFEST"; then
        echo -e "${GREEN}✓ audit-log-maxage=8 (correct)${NC}"
    else
        echo -e "${YELLOW}⚠ audit-log-maxage should be 8 days${NC}"
    fi

    if grep -q "audit-log-maxsize=9" "$API_SERVER_MANIFEST"; then
        echo -e "${GREEN}✓ audit-log-maxsize=9 (correct)${NC}"
    else
        echo -e "${YELLOW}⚠ audit-log-maxsize should be 9 MB${NC}"
    fi

    if grep -q "audit-log-maxbackup=3" "$API_SERVER_MANIFEST"; then
        echo -e "${GREEN}✓ audit-log-maxbackup=3 (correct)${NC}"
    else
        echo -e "${YELLOW}⚠ audit-log-maxbackup should be 3${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot verify API server config (not on control plane)${NC}"
fi

# Check secret audit log
echo ""
echo "Checking captured audit log..."

if [ -f "/opt/course/14/secret-audit.log" ]; then
    echo -e "${GREEN}✓ Secret audit log captured${NC}"

    # Verify it contains the expected content
    if grep -q "test-secret" /opt/course/14/secret-audit.log 2>/dev/null; then
        echo -e "${GREEN}✓ Audit log contains test-secret entry${NC}"
    else
        echo -e "${YELLOW}⚠ Audit log may not contain the expected secret entry${NC}"
    fi

    if grep -q "audit-test" /opt/course/14/secret-audit.log 2>/dev/null; then
        echo -e "${GREEN}✓ Audit log shows correct namespace (audit-test)${NC}"
    else
        echo -e "${YELLOW}⚠ Audit log namespace may be incorrect${NC}"
    fi
else
    echo -e "${RED}✗ Secret audit log not found at /opt/course/14/secret-audit.log${NC}"
    PASS=false
fi

echo ""
if $PASS; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed.${NC}"
    exit 1
fi
