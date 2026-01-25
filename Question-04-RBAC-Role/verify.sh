#!/bin/bash
# Verify Question 04 - RBAC Role

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking RBAC configuration in namespace 'cicd-ns'..."
echo ""

# Check namespace
if kubectl get namespace cicd-ns &>/dev/null; then
    echo -e "${GREEN}✓ Namespace 'cicd-ns' exists${NC}"
else
    echo -e "${RED}✗ Namespace 'cicd-ns' not found${NC}"
    PASS=false
fi

# Check ServiceAccount
if kubectl get serviceaccount deploy-sa -n cicd-ns &>/dev/null; then
    echo -e "${GREEN}✓ ServiceAccount 'deploy-sa' exists${NC}"
else
    echo -e "${RED}✗ ServiceAccount 'deploy-sa' not found${NC}"
    PASS=false
fi

# Check Role
if kubectl get role deployment-manager -n cicd-ns &>/dev/null; then
    echo -e "${GREEN}✓ Role 'deployment-manager' exists${NC}"

    # Check deployments permissions (full access)
    DEPLOY_VERBS=$(kubectl get role deployment-manager -n cicd-ns -o json | jq -r '.rules[] | select(.resources | index("deployments")) | .verbs[]' 2>/dev/null | sort | tr '\n' ' ')
    if echo "$DEPLOY_VERBS" | grep -q "create" && echo "$DEPLOY_VERBS" | grep -q "delete" && echo "$DEPLOY_VERBS" | grep -q "get"; then
        echo -e "${GREEN}✓ Deployments: Full access permissions${NC}"
    else
        echo -e "${RED}✗ Deployments should have full access (get, list, watch, create, update, patch, delete)${NC}"
        PASS=false
    fi

    # Check pods permissions (read access)
    PODS_VERBS=$(kubectl get role deployment-manager -n cicd-ns -o json | jq -r '.rules[] | select(.resources | index("pods")) | .verbs[]' 2>/dev/null | sort | tr '\n' ' ')
    if echo "$PODS_VERBS" | grep -q "get" && echo "$PODS_VERBS" | grep -q "list" && echo "$PODS_VERBS" | grep -q "watch"; then
        echo -e "${GREEN}✓ Pods: GET, LIST, WATCH permissions${NC}"
    else
        echo -e "${RED}✗ Pods should have GET, LIST, WATCH permissions${NC}"
        PASS=false
    fi

    # Check pods/log permissions (read access - question requirement)
    PODS_LOG_VERBS=$(kubectl get role deployment-manager -n cicd-ns -o json | jq -r '.rules[] | select(.resources | index("pods/log")) | .verbs[]' 2>/dev/null | sort | tr '\n' ' ')
    if echo "$PODS_LOG_VERBS" | grep -q "get"; then
        echo -e "${GREEN}✓ pods/log: GET permission${NC}"
    else
        echo -e "${RED}✗ pods/log should have GET permission${NC}"
        PASS=false
    fi

    # Check services permissions (read only)
    SVC_VERBS=$(kubectl get role deployment-manager -n cicd-ns -o json | jq -r '.rules[] | select(.resources | index("services")) | .verbs[]' 2>/dev/null | sort | tr '\n' ' ')
    if echo "$SVC_VERBS" | grep -q "get" && echo "$SVC_VERBS" | grep -q "list"; then
        echo -e "${GREEN}✓ Services: GET, LIST permissions${NC}"
    else
        echo -e "${RED}✗ Services should have GET, LIST permissions${NC}"
        PASS=false
    fi

    # Check configmaps permissions (read only)
    CM_VERBS=$(kubectl get role deployment-manager -n cicd-ns -o json | jq -r '.rules[] | select(.resources | index("configmaps")) | .verbs[]' 2>/dev/null | sort | tr '\n' ' ')
    if echo "$CM_VERBS" | grep -q "get" && echo "$CM_VERBS" | grep -q "list"; then
        echo -e "${GREEN}✓ ConfigMaps: GET, LIST permissions${NC}"
    else
        echo -e "${RED}✗ ConfigMaps should have GET, LIST permissions${NC}"
        PASS=false
    fi

    # Check NO secrets access (critical)
    SECRETS_VERBS=$(kubectl get role deployment-manager -n cicd-ns -o json | jq -r '.rules[] | select(.resources | index("secrets")) | .verbs[]' 2>/dev/null)
    if [ -z "$SECRETS_VERBS" ]; then
        echo -e "${GREEN}✓ No secrets access (security requirement)${NC}"
    else
        echo -e "${RED}✗ Role should NOT have access to secrets${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Role 'deployment-manager' not found${NC}"
    PASS=false
fi

# Check RoleBinding
if kubectl get rolebinding deploy-sa-binding -n cicd-ns &>/dev/null; then
    echo -e "${GREEN}✓ RoleBinding 'deploy-sa-binding' exists${NC}"

    # Check binding references correct role
    ROLE_REF=$(kubectl get rolebinding deploy-sa-binding -n cicd-ns -o jsonpath='{.roleRef.name}')
    if [ "$ROLE_REF" == "deployment-manager" ]; then
        echo -e "${GREEN}✓ RoleBinding references 'deployment-manager'${NC}"
    else
        echo -e "${RED}✗ RoleBinding should reference 'deployment-manager'${NC}"
        PASS=false
    fi

    # Check binding references correct service account
    SUBJECT=$(kubectl get rolebinding deploy-sa-binding -n cicd-ns -o jsonpath='{.subjects[0].name}')
    if [ "$SUBJECT" == "deploy-sa" ]; then
        echo -e "${GREEN}✓ RoleBinding binds to 'deploy-sa'${NC}"
    else
        echo -e "${RED}✗ RoleBinding should bind to 'deploy-sa'${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ RoleBinding 'deploy-sa-binding' not found${NC}"
    PASS=false
fi

# Check manifest files saved
echo ""
echo "Checking manifest files..."
if [ -f "/opt/course/04/sa.yaml" ]; then
    echo -e "${GREEN}✓ sa.yaml saved${NC}"
else
    echo -e "${RED}✗ sa.yaml not found at /opt/course/04/sa.yaml${NC}"
    PASS=false
fi

if [ -f "/opt/course/04/role.yaml" ]; then
    echo -e "${GREEN}✓ role.yaml saved${NC}"
else
    echo -e "${RED}✗ role.yaml not found at /opt/course/04/role.yaml${NC}"
    PASS=false
fi

if [ -f "/opt/course/04/rolebinding.yaml" ]; then
    echo -e "${GREEN}✓ rolebinding.yaml saved${NC}"
else
    echo -e "${RED}✗ rolebinding.yaml not found at /opt/course/04/rolebinding.yaml${NC}"
    PASS=false
fi

if [ -f "/opt/course/04/auth-test.txt" ]; then
    echo -e "${GREEN}✓ auth-test.txt saved${NC}"
else
    echo -e "${RED}✗ auth-test.txt not found at /opt/course/04/auth-test.txt${NC}"
    PASS=false
fi

if $PASS; then
    exit 0
else
    exit 1
fi
