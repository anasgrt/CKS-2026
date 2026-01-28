#!/bin/bash
# Verify Question 21 - Gatekeeper Image Registry Restriction
# Based on real CKS exam patterns (2025/2026)

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true
SCORE=0
TOTAL=8

echo "=============================================="
echo "Verifying Gatekeeper Image Registry Restriction"
echo "=============================================="
echo ""

# Pre-check: Verify Gatekeeper is running
echo "Pre-check: Gatekeeper installation"
if kubectl get pods -n gatekeeper-system 2>/dev/null | grep -q "Running"; then
    echo -e "${GREEN}✓ Gatekeeper is running${NC}"
else
    echo -e "${RED}✗ Gatekeeper is not running - run setup.sh first${NC}"
    exit 1
fi

# Pre-check: Verify test namespace exists
echo "Pre-check: Test namespace"
if kubectl get namespace gatekeeper-test &>/dev/null; then
    echo -e "${GREEN}✓ gatekeeper-test namespace exists${NC}"
else
    echo -e "${YELLOW}⚠ gatekeeper-test namespace not found - creating it${NC}"
    kubectl create namespace gatekeeper-test
fi
echo ""

# Check 1: ConstraintTemplate exists and saved
echo "Check 1: ConstraintTemplate"
if kubectl get constrainttemplate k8sallowedrepos &>/dev/null; then
    echo -e "${GREEN}✓ ConstraintTemplate 'k8sallowedrepos' exists${NC}"
    ((SCORE++))
else
    echo -e "${RED}✗ ConstraintTemplate 'k8sallowedrepos' not found${NC}"
    PASS=false
fi

if [ -f "/opt/course/21/constraint-template.yaml" ]; then
    echo -e "${GREEN}✓ constraint-template.yaml saved to /opt/course/21/${NC}"
    ((SCORE++))
else
    echo -e "${RED}✗ constraint-template.yaml not saved to /opt/course/21/${NC}"
    PASS=false
fi
echo ""

# Check 2: ConstraintTemplate has correct Rego logic
echo "Check 2: ConstraintTemplate content"
if kubectl get constrainttemplate k8sallowedrepos -o yaml 2>/dev/null | grep -q "startswith"; then
    echo -e "${GREEN}✓ Template uses startswith() for prefix matching${NC}"
    ((SCORE++))
else
    echo -e "${RED}✗ Template should use startswith() to check image prefixes${NC}"
    PASS=false
fi

if kubectl get constrainttemplate k8sallowedrepos -o yaml 2>/dev/null | grep -q "violation"; then
    echo -e "${GREEN}✓ Template defines violation rules${NC}"
else
    echo -e "${YELLOW}⚠ Template should define violation rules${NC}"
fi
echo ""

# Check 3: Constraint exists and saved
echo "Check 3: Constraint"
if kubectl get k8sallowedrepos allowed-repos &>/dev/null; then
    echo -e "${GREEN}✓ Constraint 'allowed-repos' exists${NC}"
    ((SCORE++))
else
    echo -e "${RED}✗ Constraint 'allowed-repos' not found${NC}"
    PASS=false
fi

if [ -f "/opt/course/21/constraint.yaml" ]; then
    echo -e "${GREEN}✓ constraint.yaml saved to /opt/course/21/${NC}"
    ((SCORE++))
else
    echo -e "${RED}✗ constraint.yaml not saved to /opt/course/21/${NC}"
    PASS=false
fi
echo ""

# Check 4: Constraint has required allowed repos
echo "Check 4: Allowed repositories configuration"
CONSTRAINT_YAML=$(kubectl get k8sallowedrepos allowed-repos -o yaml 2>/dev/null)

if echo "$CONSTRAINT_YAML" | grep -q "docker.io/library/"; then
    echo -e "${GREEN}✓ docker.io/library/ is in allowed repos${NC}"
else
    echo -e "${RED}✗ docker.io/library/ should be in allowed repos${NC}"
    PASS=false
fi

if echo "$CONSTRAINT_YAML" | grep -q "gcr.io/google-containers/"; then
    echo -e "${GREEN}✓ gcr.io/google-containers/ is in allowed repos${NC}"
else
    echo -e "${RED}✗ gcr.io/google-containers/ should be in allowed repos${NC}"
    PASS=false
fi

if echo "$CONSTRAINT_YAML" | grep -q "registry.k8s.io/"; then
    echo -e "${GREEN}✓ registry.k8s.io/ is in allowed repos${NC}"
else
    echo -e "${RED}✗ registry.k8s.io/ should be in allowed repos${NC}"
    PASS=false
fi
echo ""

# Check 5: Constraint applies to Pods
echo "Check 5: Constraint applies to Pods"
if echo "$CONSTRAINT_YAML" | grep -q 'kinds:' && echo "$CONSTRAINT_YAML" | grep -q 'Pod'; then
    echo -e "${GREEN}✓ Constraint applies to Pod resources${NC}"
    ((SCORE++))
else
    echo -e "${RED}✗ Constraint should apply to Pod resources${NC}"
    PASS=false
fi
echo ""

# Check 6: Test policy enforcement - allowed image
echo "Check 6: Policy allows approved images"
# Clean up any existing test pods
kubectl delete pod test-allowed -n gatekeeper-test --ignore-not-found=true &>/dev/null
kubectl delete pod test-disallowed -n gatekeeper-test --ignore-not-found=true &>/dev/null

# Wait for constraint to sync with Gatekeeper
echo "  Waiting for constraint to sync..."
sleep 3

if kubectl run test-allowed --image=docker.io/library/nginx:alpine -n gatekeeper-test --restart=Never 2>/dev/null; then
    echo -e "${GREEN}✓ Allowed image (docker.io/library/nginx:alpine) was accepted${NC}"
    ((SCORE++))
    kubectl delete pod test-allowed -n gatekeeper-test --ignore-not-found=true &>/dev/null
else
    echo -e "${RED}✗ Allowed image should be accepted${NC}"
    PASS=false
fi
echo ""

# Check 7: Test policy enforcement - disallowed image
echo "Check 7: Policy rejects unauthorized images"
if kubectl run test-disallowed --image=quay.io/unauthorized/app:v1 -n gatekeeper-test --restart=Never 2>&1 | grep -qi "not from an allowed\|violation\|denied"; then
    echo -e "${GREEN}✓ Disallowed image (quay.io/unauthorized/app:v1) was rejected${NC}"
    ((SCORE++))
else
    # Check if the pod was actually created (policy not working)
    if kubectl get pod test-disallowed -n gatekeeper-test &>/dev/null; then
        echo -e "${RED}✗ Disallowed image should be rejected but pod was created${NC}"
        kubectl delete pod test-disallowed -n gatekeeper-test --ignore-not-found=true &>/dev/null
        PASS=false
    else
        echo -e "${GREEN}✓ Disallowed image was rejected (pod not created)${NC}"
        ((SCORE++))
    fi
fi
echo ""

# Check 8: Rejected error saved
echo "Check 8: Rejection error captured"
if [ -f "/opt/course/21/rejected-error.txt" ]; then
    if grep -qi "not from an allowed\|violation\|denied\|forbidden" /opt/course/21/rejected-error.txt; then
        echo -e "${GREEN}✓ Rejection error saved to /opt/course/21/rejected-error.txt${NC}"
    else
        echo -e "${YELLOW}⚠ rejected-error.txt exists but may not contain rejection message${NC}"
    fi
else
    echo -e "${YELLOW}⚠ rejected-error.txt not found - remember to capture rejection error${NC}"
fi
echo ""

# Summary
echo "=============================================="
echo "VERIFICATION SUMMARY"
echo "=============================================="
echo ""
echo -e "Score: ${SCORE}/${TOTAL}"
echo ""

if [ "$PASS" = true ]; then
    echo -e "${GREEN}✓ All critical checks PASSED${NC}"
    echo ""
    echo "Great job! The Gatekeeper image registry restriction is correctly configured."
else
    echo -e "${RED}✗ Some checks FAILED${NC}"
    echo ""
    echo "Review the failed checks above and fix the issues."
fi

echo ""
echo "=============================================="
echo "QUICK REFERENCE"
echo "=============================================="
echo ""
echo "View ConstraintTemplate:  kubectl get constrainttemplate k8sallowedrepos -o yaml"
echo "View Constraint:          kubectl get k8sallowedrepos allowed-repos -o yaml"
echo "Check violations:         kubectl describe k8sallowedrepos allowed-repos"
echo "Test allowed:             kubectl run test --image=docker.io/library/nginx:alpine -n gatekeeper-test"
echo "Test disallowed:          kubectl run test --image=quay.io/some/image:v1 -n gatekeeper-test"
