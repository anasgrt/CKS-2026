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
echo "Checking API server configuration on controlplane..."

API_SERVER_MANIFEST="/var/lib/rancher/rke2/agent/pod-manifests/kube-apiserver.yaml"

# Check via SSH to control plane
if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5 controlplane "test -f $API_SERVER_MANIFEST" 2>/dev/null; then
    # Check anonymous-auth
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR controlplane "grep -q '\-\-anonymous-auth=false' $API_SERVER_MANIFEST" 2>/dev/null; then
        echo -e "${GREEN}✓ anonymous-auth=false is set${NC}"
    else
        echo -e "${RED}✗ anonymous-auth should be set to false${NC}"
        PASS=false
    fi

    # Check authorization-mode includes Node,RBAC
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR controlplane "grep -q '\-\-authorization-mode=Node,RBAC' $API_SERVER_MANIFEST" 2>/dev/null; then
        echo -e "${GREEN}✓ authorization-mode=Node,RBAC is set${NC}"
    else
        echo -e "${RED}✗ authorization-mode should be Node,RBAC${NC}"
        PASS=false
    fi

    # Check profiling is disabled
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR controlplane "grep -q '\-\-profiling=false' $API_SERVER_MANIFEST" 2>/dev/null; then
        echo -e "${GREEN}✓ profiling=false is set${NC}"
    else
        echo -e "${RED}✗ profiling should be set to false${NC}"
        PASS=false
    fi
else
    echo -e "${YELLOW}⚠ Cannot verify API server manifest (cannot SSH to controlplane)${NC}"
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

# Check kubelet service file permissions on worker (CIS 4.1.1)
echo ""
echo "Checking kubelet service file permissions on node01..."

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5"
SERVICE_FILE="/usr/local/lib/systemd/system/rke2-agent.service"

if ssh $SSH_OPTS node01 "test -f $SERVICE_FILE" 2>/dev/null; then
    # Check permissions are 600 or more restrictive
    PERMS=$(ssh $SSH_OPTS node01 "stat -c %a $SERVICE_FILE" 2>/dev/null)
    if [ "$PERMS" = "600" ] || [ "$PERMS" = "400" ]; then
        echo -e "${GREEN}✓ kubelet service file permissions are $PERMS (CIS 4.1.1)${NC}"
    else
        echo -e "${RED}✗ kubelet service file permissions are $PERMS, should be 600 (CIS 4.1.1)${NC}"
        PASS=false
    fi
else
    echo -e "${YELLOW}⚠ Cannot verify worker node service file (SSH not available)${NC}"
fi

if $PASS; then
    exit 0
else
    exit 1
fi
