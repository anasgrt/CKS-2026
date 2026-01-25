#!/bin/bash
# Verify Question 08 - PSA Restricted

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking Pod Security Admission configuration..."
echo ""

# Check namespace exists
if kubectl get namespace psa-restricted &>/dev/null; then
    echo -e "${GREEN}✓ Namespace 'psa-restricted' exists${NC}"

    # Check enforce label
    ENFORCE=$(kubectl get namespace psa-restricted -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')
    if [ "$ENFORCE" == "restricted" ]; then
        echo -e "${GREEN}✓ PSA enforce=restricted${NC}"
    else
        echo -e "${RED}✗ Namespace should have pod-security.kubernetes.io/enforce=restricted${NC}"
        PASS=false
    fi

    # Check warn label
    WARN=$(kubectl get namespace psa-restricted -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/warn}')
    if [ "$WARN" == "restricted" ]; then
        echo -e "${GREEN}✓ PSA warn=restricted${NC}"
    else
        echo -e "${RED}✗ Namespace should have pod-security.kubernetes.io/warn=restricted${NC}"
        PASS=false
    fi

    # Check audit label
    AUDIT=$(kubectl get namespace psa-restricted -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/audit}')
    if [ "$AUDIT" == "restricted" ]; then
        echo -e "${GREEN}✓ PSA audit=restricted${NC}"
    else
        echo -e "${RED}✗ Namespace should have pod-security.kubernetes.io/audit=restricted${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Namespace 'psa-restricted' not found${NC}"
    PASS=false
fi

# Check secure pod
echo ""
echo "Checking secure pod..."
if kubectl get pod secure-pod -n psa-restricted &>/dev/null; then
    echo -e "${GREEN}✓ Pod 'secure-pod' exists${NC}"

    # Check image (question requires nginx:alpine)
    IMAGE=$(kubectl get pod secure-pod -n psa-restricted -o jsonpath='{.spec.containers[0].image}')
    if [[ "$IMAGE" == *"nginx"* ]] && [[ "$IMAGE" == *"alpine"* ]]; then
        echo -e "${GREEN}✓ Uses nginx:alpine image${NC}"
    else
        echo -e "${RED}✗ Should use nginx:alpine image (as per question)${NC}"
        PASS=false
    fi

    # Check runAsNonRoot (PSA Restricted requirement - can be at pod or container level)
    POD_RUN_AS_NON_ROOT=$(kubectl get pod secure-pod -n psa-restricted -o jsonpath='{.spec.securityContext.runAsNonRoot}')
    CONTAINER_RUN_AS_NON_ROOT=$(kubectl get pod secure-pod -n psa-restricted -o jsonpath='{.spec.containers[0].securityContext.runAsNonRoot}')
    if [ "$POD_RUN_AS_NON_ROOT" == "true" ] || [ "$CONTAINER_RUN_AS_NON_ROOT" == "true" ]; then
        echo -e "${GREEN}✓ runAsNonRoot: true${NC}"
    else
        echo -e "${RED}✗ Must have runAsNonRoot: true (PSA Restricted requirement)${NC}"
        PASS=false
    fi

    # Check capabilities dropped (PSA Restricted requirement)
    DROP_CAPS=$(kubectl get pod secure-pod -n psa-restricted -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop}')
    if [[ "$DROP_CAPS" == *"ALL"* ]]; then
        echo -e "${GREEN}✓ All capabilities dropped${NC}"
    else
        echo -e "${RED}✗ Must drop ALL capabilities (PSA Restricted requirement)${NC}"
        PASS=false
    fi

    # Check seccompProfile (PSA Restricted requirement - MUST be RuntimeDefault or Localhost)
    POD_SECCOMP=$(kubectl get pod secure-pod -n psa-restricted -o jsonpath='{.spec.securityContext.seccompProfile.type}')
    CONTAINER_SECCOMP=$(kubectl get pod secure-pod -n psa-restricted -o jsonpath='{.spec.containers[0].securityContext.seccompProfile.type}')
    if [ "$POD_SECCOMP" == "RuntimeDefault" ] || [ "$POD_SECCOMP" == "Localhost" ] || \
       [ "$CONTAINER_SECCOMP" == "RuntimeDefault" ] || [ "$CONTAINER_SECCOMP" == "Localhost" ]; then
        echo -e "${GREEN}✓ seccompProfile: RuntimeDefault or Localhost${NC}"
    else
        echo -e "${RED}✗ Must have seccompProfile type RuntimeDefault or Localhost (PSA Restricted requirement)${NC}"
        PASS=false
    fi

    # Check allowPrivilegeEscalation (PSA Restricted requirement)
    ALLOW_PRIV=$(kubectl get pod secure-pod -n psa-restricted -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation}')
    if [ "$ALLOW_PRIV" == "false" ]; then
        echo -e "${GREEN}✓ allowPrivilegeEscalation: false${NC}"
    else
        echo -e "${RED}✗ Must have allowPrivilegeEscalation: false (PSA Restricted requirement)${NC}"
        PASS=false
    fi

    # Note: readOnlyRootFilesystem is NOT a PSA Restricted requirement per K8s docs
    # It's a security best practice but not enforced by PSA
else
    echo -e "${RED}✗ Pod 'secure-pod' not found${NC}"
    PASS=false
fi

# Check pod.yaml file
echo ""
echo "Checking output files..."
if [ -f "/opt/course/08/pod.yaml" ]; then
    echo -e "${GREEN}✓ pod.yaml saved to /opt/course/08/pod.yaml${NC}"
else
    echo -e "${RED}✗ pod.yaml not found at /opt/course/08/pod.yaml${NC}"
    PASS=false
fi

# Check rejected-error.txt
if [ -f "/opt/course/08/rejected-error.txt" ]; then
    echo -e "${GREEN}✓ rejected-error.txt exists${NC}"

    # Verify it contains PSA violation message
    if grep -qi "violates\|forbidden\|denied" /opt/course/08/rejected-error.txt 2>/dev/null; then
        echo -e "${GREEN}✓ rejected-error.txt contains rejection message${NC}"
    else
        echo -e "${RED}✗ rejected-error.txt should contain PSA violation message${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ rejected-error.txt not found at /opt/course/08/rejected-error.txt${NC}"
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
