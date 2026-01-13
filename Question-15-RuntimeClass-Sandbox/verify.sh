#!/bin/bash
# Verify Question 15 - RuntimeClass Sandbox

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking RuntimeClass configuration..."
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
