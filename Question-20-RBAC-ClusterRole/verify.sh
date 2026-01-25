#!/bin/bash
# Verify Question 20 - RBAC ClusterRole

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking Cluster RBAC configuration..."
echo ""

# Check namespace
if kubectl get namespace monitoring &>/dev/null; then
    echo -e "${GREEN}✓ Namespace 'monitoring' exists${NC}"
else
    echo -e "${RED}✗ Namespace 'monitoring' not found${NC}"
    PASS=false
fi

# Check ServiceAccount
if kubectl get serviceaccount monitor-sa -n monitoring &>/dev/null; then
    echo -e "${GREEN}✓ ServiceAccount 'monitor-sa' exists${NC}"
else
    echo -e "${RED}✗ ServiceAccount 'monitor-sa' not found in monitoring namespace${NC}"
    PASS=false
fi

# Check ClusterRole
if kubectl get clusterrole cluster-monitor &>/dev/null; then
    echo -e "${GREEN}✓ ClusterRole 'cluster-monitor' exists${NC}"

    # Check pods permission
    PODS=$(kubectl get clusterrole cluster-monitor -o json | jq -r '.rules[] | select(.resources | index("pods")) | .verbs[]' 2>/dev/null | sort -u | tr '\n' ' ')
    if echo "$PODS" | grep -q "get" && echo "$PODS" | grep -q "list" && echo "$PODS" | grep -q "watch"; then
        echo -e "${GREEN}✓ Pods: GET, LIST, WATCH permissions${NC}"
    else
        echo -e "${RED}✗ Should have GET, LIST, WATCH on pods${NC}"
        PASS=false
    fi

    # Check nodes permission
    NODES=$(kubectl get clusterrole cluster-monitor -o json | jq -r '.rules[] | select(.resources | index("nodes")) | .verbs[]' 2>/dev/null | sort -u | tr '\n' ' ')
    if echo "$NODES" | grep -q "get" && echo "$NODES" | grep -q "list" && echo "$NODES" | grep -q "watch"; then
        echo -e "${GREEN}✓ Nodes: GET, LIST, WATCH permissions${NC}"
    else
        echo -e "${RED}✗ Should have GET, LIST, WATCH on nodes${NC}"
        PASS=false
    fi

    # Check pods/log
    LOGS=$(kubectl get clusterrole cluster-monitor -o json | jq -r '.rules[] | select(.resources | index("pods/log")) | .verbs[]' 2>/dev/null | sort -u | tr '\n' ' ')
    if echo "$LOGS" | grep -q "get"; then
        echo -e "${GREEN}✓ pods/log: GET permission${NC}"
    else
        echo -e "${RED}✗ Should have GET on pods/log${NC}"
        PASS=false
    fi

    # Check NO write permissions
    ALL_VERBS=$(kubectl get clusterrole cluster-monitor -o json | jq -r '.rules[].verbs[]' 2>/dev/null | sort -u | tr '\n' ' ')
    if echo "$ALL_VERBS" | grep -qE "create|update|delete|patch"; then
        echo -e "${RED}✗ Should NOT have write permissions (create/update/delete/patch)${NC}"
        PASS=false
    else
        echo -e "${GREEN}✓ No write permissions (read-only)${NC}"
    fi
else
    echo -e "${RED}✗ ClusterRole 'cluster-monitor' not found${NC}"
    PASS=false
fi

# Check ClusterRoleBinding
if kubectl get clusterrolebinding cluster-monitor-binding &>/dev/null; then
    echo -e "${GREEN}✓ ClusterRoleBinding 'cluster-monitor-binding' exists${NC}"

    ROLE_REF=$(kubectl get clusterrolebinding cluster-monitor-binding -o jsonpath='{.roleRef.name}')
    if [ "$ROLE_REF" == "cluster-monitor" ]; then
        echo -e "${GREEN}✓ Binding references 'cluster-monitor'${NC}"
    else
        echo -e "${RED}✗ Binding should reference 'cluster-monitor'${NC}"
        PASS=false
    fi

    SUBJECT=$(kubectl get clusterrolebinding cluster-monitor-binding -o jsonpath='{.subjects[0].name}')
    if [ "$SUBJECT" == "monitor-sa" ]; then
        echo -e "${GREEN}✓ Binding subjects include 'monitor-sa'${NC}"
    else
        echo -e "${RED}✗ Binding should include 'monitor-sa' subject${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ ClusterRoleBinding 'cluster-monitor-binding' not found${NC}"
    PASS=false
fi

# Test access
echo ""
echo "Testing access..."
if kubectl auth can-i list pods --all-namespaces --as=system:serviceaccount:monitoring:monitor-sa 2>/dev/null; then
    echo -e "${GREEN}✓ ServiceAccount can list pods cluster-wide${NC}"
else
    echo -e "${RED}✗ ServiceAccount should be able to list pods cluster-wide${NC}"
    PASS=false
fi

if ! kubectl auth can-i delete pods --as=system:serviceaccount:monitoring:monitor-sa 2>/dev/null; then
    echo -e "${GREEN}✓ ServiceAccount cannot delete pods (read-only)${NC}"
else
    echo -e "${RED}✗ ServiceAccount should NOT be able to delete pods${NC}"
    PASS=false
fi

if ! kubectl auth can-i get secrets --as=system:serviceaccount:monitoring:monitor-sa 2>/dev/null; then
    echo -e "${GREEN}✓ ServiceAccount cannot access secrets${NC}"
else
    echo -e "${RED}✗ ServiceAccount should NOT have access to secrets${NC}"
    PASS=false
fi

# Check NO configmaps access (question requirement)
if ! kubectl auth can-i get configmaps --as=system:serviceaccount:monitoring:monitor-sa 2>/dev/null; then
    echo -e "${GREEN}✓ ServiceAccount cannot access configmaps${NC}"
else
    echo -e "${RED}✗ ServiceAccount should NOT have access to configmaps${NC}"
    PASS=false
fi

# Check NO pods/exec access (question requirement)
if ! kubectl auth can-i create pods/exec --as=system:serviceaccount:monitoring:monitor-sa 2>/dev/null; then
    echo -e "${GREEN}✓ ServiceAccount cannot exec into pods${NC}"
else
    echo -e "${RED}✗ ServiceAccount should NOT be able to exec into pods${NC}"
    PASS=false
fi

# Check manifest files
echo ""
echo "Checking manifest files..."
for file in clusterrole.yaml sa.yaml clusterrolebinding.yaml; do
    if [ -f "/opt/course/20/$file" ]; then
        echo -e "${GREEN}✓ $file saved${NC}"
    else
        echo -e "${RED}✗ $file not found at /opt/course/20/$file${NC}"
        PASS=false
    fi
done

if [ -f "/opt/course/20/permissions-test.txt" ]; then
    echo -e "${GREEN}✓ permissions-test.txt saved${NC}"
else
    echo -e "${RED}✗ permissions-test.txt not found${NC}"
    PASS=false
fi

if $PASS; then
    exit 0
else
    exit 1
fi
