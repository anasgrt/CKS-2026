#!/bin/bash
# Verify Question 05 - ServiceAccount Security

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking ServiceAccount security in namespace 'secure-ns'..."
echo ""

# Check ServiceAccount exists
if kubectl get serviceaccount restricted-sa -n secure-ns &>/dev/null; then
    echo -e "${GREEN}✓ ServiceAccount 'restricted-sa' exists${NC}"

    # Check automountServiceAccountToken on SA
    SA_TOKEN=$(kubectl get serviceaccount restricted-sa -n secure-ns -o jsonpath='{.automountServiceAccountToken}')
    if [ "$SA_TOKEN" == "false" ]; then
        echo -e "${GREEN}✓ ServiceAccount has automountServiceAccountToken: false${NC}"
    else
        echo -e "${RED}✗ ServiceAccount should have automountServiceAccountToken: false${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ ServiceAccount 'restricted-sa' not found${NC}"
    PASS=false
fi

# Check Role exists
if kubectl get role pod-reader -n secure-ns &>/dev/null; then
    echo -e "${GREEN}✓ Role 'pod-reader' exists${NC}"

    # Verify Role has correct permissions
    PODS_VERBS=$(kubectl get role pod-reader -n secure-ns -o json | jq -r '.rules[] | select(.resources | index("pods")) | .verbs[]' 2>/dev/null | sort | tr '\n' ' ')
    if echo "$PODS_VERBS" | grep -q "get" && echo "$PODS_VERBS" | grep -q "list"; then
        echo -e "${GREEN}✓ Role has get/list pods permissions${NC}"
    else
        echo -e "${RED}✗ Role should have get, list on pods${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Role 'pod-reader' not found${NC}"
    PASS=false
fi

# Check RoleBinding exists
if kubectl get rolebinding restricted-sa-binding -n secure-ns &>/dev/null; then
    echo -e "${GREEN}✓ RoleBinding 'restricted-sa-binding' exists${NC}"
else
    echo -e "${RED}✗ RoleBinding 'restricted-sa-binding' not found${NC}"
    PASS=false
fi

# Check Deployment uses correct SA
DEPLOY_SA=$(kubectl get deployment insecure-app -n secure-ns -o jsonpath='{.spec.template.spec.serviceAccountName}')
if [ "$DEPLOY_SA" == "restricted-sa" ]; then
    echo -e "${GREEN}✓ Deployment uses 'restricted-sa' ServiceAccount${NC}"
else
    echo -e "${RED}✗ Deployment should use 'restricted-sa' ServiceAccount${NC}"
    PASS=false
fi

# Check automountServiceAccountToken (either SA or Pod level is sufficient per K8s docs)
SA_TOKEN=$(kubectl get serviceaccount restricted-sa -n secure-ns -o jsonpath='{.automountServiceAccountToken}')
POD_TOKEN=$(kubectl get deployment insecure-app -n secure-ns -o jsonpath='{.spec.template.spec.automountServiceAccountToken}')
if [ "$SA_TOKEN" == "false" ] || [ "$POD_TOKEN" == "false" ]; then
    echo -e "${GREEN}✓ automountServiceAccountToken disabled (SA or Pod level)${NC}"
else
    echo -e "${RED}✗ automountServiceAccountToken should be false on SA or Pod${NC}"
    PASS=false
fi

# Verify no token is mounted in running pod
echo ""
echo "Checking running pod..."
POD_NAME=$(kubectl get pods -n secure-ns -l app=insecure-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    TOKEN_MOUNT=$(kubectl get pod $POD_NAME -n secure-ns -o jsonpath='{.spec.containers[0].volumeMounts}' | grep -c serviceaccount || true)
    if [ "$TOKEN_MOUNT" == "0" ]; then
        echo -e "${GREEN}✓ No service account token mounted in pod${NC}"
    else
        echo -e "${RED}✗ Service account token should not be mounted${NC}"
        PASS=false
    fi
fi

# Check manifest files saved
echo ""
echo "Checking manifest files..."
for file in sa.yaml role.yaml rolebinding.yaml deployment.yaml; do
    if [ -f "/opt/course/05/$file" ]; then
        echo -e "${GREEN}✓ $file saved${NC}"
    else
        echo -e "${RED}✗ $file not found at /opt/course/05/$file${NC}"
        PASS=false
    fi
done

if $PASS; then
    exit 0
else
    exit 1
fi
