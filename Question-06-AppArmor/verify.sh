#!/bin/bash
# Verify Question 06 - AppArmor

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking AppArmor configuration..."
echo ""

# Check pod exists
if kubectl get pod secured-pod -n apparmor-ns &>/dev/null; then
    echo -e "${GREEN}✓ Pod 'secured-pod' exists${NC}"

    # Check for AppArmor in securityContext (GA method K8s 1.30+)
    CONTAINER_PROFILE=$(kubectl get pod secured-pod -n apparmor-ns -o jsonpath='{.spec.containers[0].securityContext.appArmorProfile.localhostProfile}' 2>/dev/null)
    CONTAINER_TYPE=$(kubectl get pod secured-pod -n apparmor-ns -o jsonpath='{.spec.containers[0].securityContext.appArmorProfile.type}' 2>/dev/null)

    if [ "$CONTAINER_PROFILE" == "k8s-deny-write" ] && [ "$CONTAINER_TYPE" == "Localhost" ]; then
        echo -e "${GREEN}✓ AppArmor securityContext configured correctly${NC}"
        echo -e "${GREEN}✓ Profile type: Localhost${NC}"
        echo -e "${GREEN}✓ Profile name: k8s-deny-write${NC}"
    else
        echo -e "${RED}✗ AppArmor profile 'k8s-deny-write' not configured correctly${NC}"
        echo "  Expected: type=Localhost, localhostProfile=k8s-deny-write"
        echo "  Found: type=$CONTAINER_TYPE, localhostProfile=$CONTAINER_PROFILE"
        PASS=false
    fi

    # Check image
    IMAGE=$(kubectl get pod secured-pod -n apparmor-ns -o jsonpath='{.spec.containers[0].image}')
    if [[ "$IMAGE" == *"nginx"* ]]; then
        echo -e "${GREEN}✓ Using nginx image${NC}"
    else
        echo -e "${RED}✗ Should use nginx image${NC}"
        PASS=false
    fi

    # Check pod is running
    STATUS=$(kubectl get pod secured-pod -n apparmor-ns -o jsonpath='{.status.phase}')
    if [ "$STATUS" == "Running" ]; then
        echo -e "${GREEN}✓ Pod is running${NC}"
    else
        echo -e "${RED}✗ Pod is not running (status: $STATUS)${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Pod 'secured-pod' not found in namespace 'apparmor-ns'${NC}"
    PASS=false
fi

# Check output files
echo ""
echo "Checking output files..."
if [ -f "/opt/course/06/pod.yaml" ]; then
    echo -e "${GREEN}✓ pod.yaml saved${NC}"
else
    echo -e "${RED}✗ pod.yaml not found at /opt/course/06/pod.yaml${NC}"
    PASS=false
fi

if [ -f "/opt/course/06/apparmor-test.txt" ]; then
    echo -e "${GREEN}✓ apparmor-test.txt saved${NC}"
else
    echo -e "${RED}✗ apparmor-test.txt not found at /opt/course/06/apparmor-test.txt${NC}"
    PASS=false
fi

if $PASS; then
    exit 0
else
    exit 1
fi
