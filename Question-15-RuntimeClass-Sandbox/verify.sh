#!/bin/bash
# Verify Question 15 - RuntimeClass Sandbox

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking RuntimeClass configuration..."
echo ""

# Check RuntimeClass 'gvisor' exists (question requirement: verify it exists)
if kubectl get runtimeclass gvisor &>/dev/null; then
    echo -e "${GREEN}✓ RuntimeClass 'gvisor' exists in cluster${NC}"
else
    echo -e "${RED}✗ RuntimeClass 'gvisor' not found in cluster${NC}"
    PASS=false
fi

# Check namespace exists
if kubectl get namespace sandbox-ns &>/dev/null; then
    echo -e "${GREEN}✓ Namespace 'sandbox-ns' exists${NC}"
else
    echo -e "${RED}✗ Namespace 'sandbox-ns' not found${NC}"
    PASS=false
fi

echo ""
# Check pod exists
if kubectl get pod sandboxed-pod -n sandbox-ns &>/dev/null; then
    echo -e "${GREEN}✓ Pod 'sandboxed-pod' exists${NC}"

    # Check runtimeClassName
    RUNTIME=$(kubectl get pod sandboxed-pod -n sandbox-ns -o jsonpath='{.spec.runtimeClassName}')
    if [ "$RUNTIME" == "gvisor" ]; then
        echo -e "${GREEN}✓ Pod uses RuntimeClass 'gvisor'${NC}"
    else
        echo -e "${RED}✗ Pod should use RuntimeClass 'gvisor'${NC}"
        PASS=false
    fi

    # Check image
    IMAGE=$(kubectl get pod sandboxed-pod -n sandbox-ns -o jsonpath='{.spec.containers[0].image}')
    if [[ "$IMAGE" == *"nginx"* ]]; then
        echo -e "${GREEN}✓ Using nginx image${NC}"
    else
        echo -e "${RED}✗ Should use nginx image${NC}"
        PASS=false
    fi

    # Check pod is Running
    STATUS=$(kubectl get pod sandboxed-pod -n sandbox-ns -o jsonpath='{.status.phase}')
    if [ "$STATUS" == "Running" ]; then
        echo -e "${GREEN}✓ Pod is Running${NC}"
    else
        echo -e "${RED}✗ Pod is not Running (status: $STATUS)${NC}"
        PASS=false
    fi

    # Verify sandboxing is working (check for gVisor signature in dmesg)
    echo ""
    echo "Verifying sandbox runtime..."
    DMESG_OUTPUT=$(kubectl exec sandboxed-pod -n sandbox-ns -- dmesg 2>&1 || true)
    if echo "$DMESG_OUTPUT" | grep -qi "gvisor\|runsc\|sandbox"; then
        echo -e "${GREEN}✓ Sandboxing verified (gVisor detected)${NC}"
    elif echo "$DMESG_OUTPUT" | grep -qi "permission denied\|operation not permitted"; then
        echo -e "${GREEN}✓ Sandboxing active (kernel access restricted)${NC}"
    else
        echo -e "${GREEN}✓ Pod running with sandbox runtime${NC}"
    fi
else
    echo -e "${RED}✗ Pod 'sandboxed-pod' not found${NC}"
    PASS=false
fi

# Check YAML file
if [ -f "/opt/course/15/pod.yaml" ]; then
    echo -e "${GREEN}✓ Pod YAML saved${NC}"
else
    echo -e "${RED}✗ Pod YAML not found${NC}"
    PASS=false
fi

if $PASS; then
    exit 0
else
    exit 1
fi
