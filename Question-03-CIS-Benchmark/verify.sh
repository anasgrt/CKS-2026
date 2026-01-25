#!/bin/bash
# Verify Question 03 - CIS Benchmark

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking CIS Benchmark fixes..."
echo ""

# Check if kube-bench output exists
if [ -f "/opt/course/03/kube-bench-before.txt" ]; then
    echo -e "${GREEN}✓ kube-bench output saved${NC}"
else
    echo -e "${RED}✗ kube-bench output not found at /opt/course/03/kube-bench-before.txt${NC}"
    PASS=false
fi

# Check if fixes.txt exists
if [ -f "/opt/course/03/fixes.txt" ]; then
    echo -e "${GREEN}✓ fixes.txt found${NC}"
else
    echo -e "${RED}✗ fixes.txt not found at /opt/course/03/fixes.txt${NC}"
    PASS=false
fi

# Check API server configuration
echo ""
echo "Checking API server configuration on key-ctrl..."

API_SERVER_MANIFEST="/var/lib/rancher/rke2/agent/pod-manifests/kube-apiserver.yaml"

# Check via SSH to control plane
if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5 key-ctrl "test -f $API_SERVER_MANIFEST" 2>/dev/null; then
    # Check anonymous-auth
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR key-ctrl "grep -q '\-\-anonymous-auth=false' $API_SERVER_MANIFEST" 2>/dev/null; then
        echo -e "${GREEN}✓ anonymous-auth=false is set${NC}"
    else
        echo -e "${RED}✗ anonymous-auth should be set to false${NC}"
        PASS=false
    fi

    # Check authorization-mode includes Node,RBAC
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR key-ctrl "grep -q '\-\-authorization-mode=Node,RBAC' $API_SERVER_MANIFEST" 2>/dev/null; then
        echo -e "${GREEN}✓ authorization-mode=Node,RBAC is set${NC}"
    else
        echo -e "${RED}✗ authorization-mode should be Node,RBAC${NC}"
        PASS=false
    fi

    # Check profiling is disabled
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR key-ctrl "grep -q '\-\-profiling=false' $API_SERVER_MANIFEST" 2>/dev/null; then
        echo -e "${GREEN}✓ profiling=false is set${NC}"
    else
        echo -e "${RED}✗ profiling should be set to false${NC}"
        PASS=false
    fi
else
    echo -e "${YELLOW}⚠ Cannot verify API server manifest (cannot SSH to key-ctrl)${NC}"
fi

# Check kube-bench after output exists
echo ""
echo "Checking final verification..."

if [ -f "/opt/course/03/kube-bench-after.txt" ]; then
    echo -e "${GREEN}✓ kube-bench-after.txt saved${NC}"
else
    echo -e "${RED}✗ kube-bench-after.txt not found at /opt/course/03/kube-bench-after.txt${NC}"
    PASS=false
fi

# Check fixes.txt mentions worker node
if [ -f "/opt/course/03/fixes.txt" ]; then
    if grep -qi "worker\|kubelet\|node" /opt/course/03/fixes.txt; then
        echo -e "${GREEN}✓ fixes.txt includes worker node changes${NC}"
    else
        echo -e "${YELLOW}⚠ fixes.txt should document worker node (kubelet) changes${NC}"
    fi
fi

# Check kubelet configuration on worker (if we can SSH)
echo ""
echo "Checking kubelet configuration on key-worker..."

if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5 key-worker 'test -f /etc/rancher/rke2/config.yaml' 2>/dev/null; then
    # Check protect-kernel-defaults
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR key-worker 'grep -q "protect-kernel-defaults" /etc/rancher/rke2/config.yaml' 2>/dev/null; then
        echo -e "${GREEN}✓ protect-kernel-defaults configured on worker${NC}"
    else
        echo -e "${YELLOW}⚠ protect-kernel-defaults not found in worker config${NC}"
    fi

    # Check read-only-port
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR key-worker 'grep -q "read-only-port" /etc/rancher/rke2/config.yaml' 2>/dev/null; then
        echo -e "${GREEN}✓ read-only-port configured on worker${NC}"
    else
        echo -e "${YELLOW}⚠ read-only-port not found in worker config${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot verify worker node config (SSH not available or config not found)${NC}"
fi

if $PASS; then
    exit 0
else
    exit 1
fi
