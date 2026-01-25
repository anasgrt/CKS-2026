#!/bin/bash
# Verify Question 07 - Seccomp

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking Seccomp configuration..."
echo ""

# Check namespace exists
if kubectl get namespace seccomp-ns &>/dev/null; then
    echo -e "${GREEN}✓ Namespace 'seccomp-ns' exists${NC}"
else
    echo -e "${RED}✗ Namespace 'seccomp-ns' not found${NC}"
    PASS=false
fi

echo ""
# Check runtime-default-pod
if kubectl get pod runtime-default-pod -n seccomp-ns &>/dev/null; then
    echo -e "${GREEN}✓ Pod 'runtime-default-pod' exists${NC}"

    # Check image (question requires nginx:alpine)
    IMAGE=$(kubectl get pod runtime-default-pod -n seccomp-ns -o jsonpath='{.spec.containers[0].image}')
    if [[ "$IMAGE" == *"nginx"* ]] && [[ "$IMAGE" == *"alpine"* ]]; then
        echo -e "${GREEN}✓ runtime-default-pod uses nginx:alpine image${NC}"
    else
        echo -e "${RED}✗ runtime-default-pod should use nginx:alpine image${NC}"
        PASS=false
    fi

    # Check pod is Running
    STATUS=$(kubectl get pod runtime-default-pod -n seccomp-ns -o jsonpath='{.status.phase}')
    if [ "$STATUS" == "Running" ]; then
        echo -e "${GREEN}✓ runtime-default-pod is Running${NC}"
    else
        echo -e "${RED}✗ runtime-default-pod is not Running (status: $STATUS)${NC}"
        PASS=false
    fi

    # Check seccomp profile type (check both pod and container level)
    SECCOMP_TYPE=$(kubectl get pod runtime-default-pod -n seccomp-ns -o jsonpath='{.spec.securityContext.seccompProfile.type}')
    CONTAINER_SECCOMP=$(kubectl get pod runtime-default-pod -n seccomp-ns -o jsonpath='{.spec.containers[0].securityContext.seccompProfile.type}')

    if [ "$SECCOMP_TYPE" == "RuntimeDefault" ] || [ "$CONTAINER_SECCOMP" == "RuntimeDefault" ]; then
        echo -e "${GREEN}✓ runtime-default-pod uses RuntimeDefault profile${NC}"
    else
        echo -e "${RED}✗ runtime-default-pod should use RuntimeDefault profile${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Pod 'runtime-default-pod' not found${NC}"
    PASS=false
fi

echo ""
# Check custom-seccomp-pod
if kubectl get pod custom-seccomp-pod -n seccomp-ns &>/dev/null; then
    echo -e "${GREEN}✓ Pod 'custom-seccomp-pod' exists${NC}"

    # Check image (question requires nginx:alpine)
    IMAGE=$(kubectl get pod custom-seccomp-pod -n seccomp-ns -o jsonpath='{.spec.containers[0].image}')
    if [[ "$IMAGE" == *"nginx"* ]] && [[ "$IMAGE" == *"alpine"* ]]; then
        echo -e "${GREEN}✓ custom-seccomp-pod uses nginx:alpine image${NC}"
    else
        echo -e "${RED}✗ custom-seccomp-pod should use nginx:alpine image${NC}"
        PASS=false
    fi

    # Check pod is Running
    STATUS=$(kubectl get pod custom-seccomp-pod -n seccomp-ns -o jsonpath='{.status.phase}')
    if [ "$STATUS" == "Running" ]; then
        echo -e "${GREEN}✓ custom-seccomp-pod is Running${NC}"
    else
        echo -e "${RED}✗ custom-seccomp-pod is not Running (status: $STATUS)${NC}"
        PASS=false
    fi

    # Check seccomp profile type and path (check both pod and container level)
    SECCOMP_TYPE=$(kubectl get pod custom-seccomp-pod -n seccomp-ns -o jsonpath='{.spec.securityContext.seccompProfile.type}')
    SECCOMP_PATH=$(kubectl get pod custom-seccomp-pod -n seccomp-ns -o jsonpath='{.spec.securityContext.seccompProfile.localhostProfile}')
    CONTAINER_SECCOMP_TYPE=$(kubectl get pod custom-seccomp-pod -n seccomp-ns -o jsonpath='{.spec.containers[0].securityContext.seccompProfile.type}')
    CONTAINER_SECCOMP_PATH=$(kubectl get pod custom-seccomp-pod -n seccomp-ns -o jsonpath='{.spec.containers[0].securityContext.seccompProfile.localhostProfile}')

    if [ "$SECCOMP_TYPE" == "Localhost" ] || [ "$CONTAINER_SECCOMP_TYPE" == "Localhost" ]; then
        echo -e "${GREEN}✓ custom-seccomp-pod uses Localhost profile type${NC}"
    else
        echo -e "${RED}✗ custom-seccomp-pod should use Localhost profile type${NC}"
        PASS=false
    fi

    if [ "$SECCOMP_PATH" == "audit-log.json" ] || [ "$CONTAINER_SECCOMP_PATH" == "audit-log.json" ]; then
        echo -e "${GREEN}✓ custom-seccomp-pod references audit-log.json${NC}"
    else
        echo -e "${RED}✗ custom-seccomp-pod should reference audit-log.json${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Pod 'custom-seccomp-pod' not found${NC}"
    PASS=false
fi

# Check manifest files saved
echo ""
echo "Checking manifest files..."
if [ -f "/opt/course/07/runtime-default-pod.yaml" ]; then
    echo -e "${GREEN}✓ runtime-default-pod.yaml saved${NC}"
else
    echo -e "${RED}✗ runtime-default-pod.yaml not found at /opt/course/07/runtime-default-pod.yaml${NC}"
    PASS=false
fi

if [ -f "/opt/course/07/custom-seccomp-pod.yaml" ]; then
    echo -e "${GREEN}✓ custom-seccomp-pod.yaml saved${NC}"
else
    echo -e "${RED}✗ custom-seccomp-pod.yaml not found at /opt/course/07/custom-seccomp-pod.yaml${NC}"
    PASS=false
fi

if [ -f "/opt/course/07/seccomp-verify.txt" ]; then
    echo -e "${GREEN}✓ seccomp-verify.txt saved${NC}"
else
    echo -e "${RED}✗ seccomp-verify.txt not found at /opt/course/07/seccomp-verify.txt${NC}"
    PASS=false
fi

if $PASS; then
    exit 0
else
    exit 1
fi
