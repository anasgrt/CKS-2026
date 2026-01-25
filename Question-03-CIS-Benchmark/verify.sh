#!/bin/bash
# Verify Question 03 - CIS Benchmark (kubeadm cluster)

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5"

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

API_SERVER_MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"

# Check via SSH to control plane
if ssh $SSH_OPTS controlplane "test -f $API_SERVER_MANIFEST" 2>/dev/null; then
    # Check anonymous-auth
    if ssh $SSH_OPTS controlplane "grep -q '\-\-anonymous-auth=false' $API_SERVER_MANIFEST" 2>/dev/null; then
        echo -e "${GREEN}✓ anonymous-auth=false is set${NC}"
    else
        echo -e "${RED}✗ anonymous-auth should be set to false${NC}"
        PASS=false
    fi

    # Check authorization-mode includes Node,RBAC
    if ssh $SSH_OPTS controlplane "grep -q '\-\-authorization-mode=Node,RBAC' $API_SERVER_MANIFEST" 2>/dev/null; then
        echo -e "${GREEN}✓ authorization-mode=Node,RBAC is set${NC}"
    else
        echo -e "${RED}✗ authorization-mode should be Node,RBAC${NC}"
        PASS=false
    fi

    # Check profiling is disabled (either false or not present)
    if ssh $SSH_OPTS controlplane "grep -q '\-\-profiling=false' $API_SERVER_MANIFEST" 2>/dev/null; then
        echo -e "${GREEN}✓ profiling=false is set${NC}"
    elif ! ssh $SSH_OPTS controlplane "grep -q '\-\-profiling=true' $API_SERVER_MANIFEST" 2>/dev/null; then
        echo -e "${GREEN}✓ profiling is not enabled${NC}"
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
    if grep -qi "worker\|kubelet\|node\|protectKernelDefaults" /opt/course/03/fixes.txt; then
        echo -e "${GREEN}✓ fixes.txt includes worker node changes${NC}"
    else
        echo -e "${YELLOW}⚠ fixes.txt should document worker node (kubelet) changes${NC}"
    fi
fi

# Check kubelet protectKernelDefaults on worker (CIS 4.2.6)
echo ""
echo "Checking kubelet configuration on node01..."

KUBELET_CONFIG="/var/lib/kubelet/config.yaml"

if ssh $SSH_OPTS node01 "test -f $KUBELET_CONFIG" 2>/dev/null; then
    # Check protectKernelDefaults is set to true
    if ssh $SSH_OPTS node01 "grep -q 'protectKernelDefaults: true' $KUBELET_CONFIG" 2>/dev/null; then
        echo -e "${GREEN}✓ protectKernelDefaults=true is set (CIS 4.2.6)${NC}"
    else
        echo -e "${RED}✗ protectKernelDefaults should be set to true (CIS 4.2.6)${NC}"
        PASS=false
    fi
else
    echo -e "${YELLOW}⚠ Cannot verify kubelet config on node01${NC}"
fi

if $PASS; then
    exit 0
else
    exit 1
fi
