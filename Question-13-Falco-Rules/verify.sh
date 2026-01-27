#!/bin/bash
# Verify Question 13 - Falco Rules
# All checks run on node01 where Falco is configured

echo "Checking Falco rule configuration on node01..."
echo ""

# Run all checks on node01 via SSH
ssh node01 bash << 'REMOTE_SCRIPT'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

# Check Falco service is running
if systemctl is-active --quiet falco-modern-bpf.service || systemctl is-active --quiet falco; then
    echo -e "${GREEN}✓ Falco service is running${NC}"
else
    echo -e "${RED}✗ Falco service is not running${NC}"
    PASS=false
fi

# Check custom rule file exists
RULE_FILE=""
if [ -f "/etc/falco/rules.d/shell-detect.yaml" ]; then
    RULE_FILE="/etc/falco/rules.d/shell-detect.yaml"
    echo -e "${GREEN}✓ Custom rule file exists at /etc/falco/rules.d/shell-detect.yaml${NC}"
else
    echo -e "${RED}✗ Custom rule not found at /etc/falco/rules.d/shell-detect.yaml${NC}"
    PASS=false
fi

if [ -n "$RULE_FILE" ]; then
    # Check rule name
    if grep -q "Shell Spawned in Container" "$RULE_FILE"; then
        echo -e "${GREEN}✓ Rule name correct${NC}"
    else
        echo -e "${RED}✗ Rule should be named 'Shell Spawned in Container'${NC}"
        PASS=false
    fi

    # Check for shell detection
    if grep -q "bash\|/bin/sh" "$RULE_FILE"; then
        echo -e "${GREEN}✓ Rule detects shells${NC}"
    else
        echo -e "${RED}✗ Rule should detect bash/sh shells${NC}"
        PASS=false
    fi

    # Check priority
    if grep -qi "warning" "$RULE_FILE"; then
        echo -e "${GREEN}✓ Priority is WARNING${NC}"
    else
        echo -e "${RED}✗ Priority should be WARNING${NC}"
        PASS=false
    fi

    # Check output format (question requires: user, command, container, pod name, namespace)
    OUTPUT_OK=true

    if grep -qi "user=" "$RULE_FILE" || grep -qi "%user" "$RULE_FILE"; then
        echo -e "${GREEN}✓ Output includes user${NC}"
    else
        echo -e "${RED}✗ Output should include user${NC}"
        OUTPUT_OK=false
    fi

    if grep -qi "command\|proc.cmdline\|proc.name" "$RULE_FILE"; then
        echo -e "${GREEN}✓ Output includes command${NC}"
    else
        echo -e "${RED}✗ Output should include command${NC}"
        OUTPUT_OK=false
    fi

    if grep -qi "container=" "$RULE_FILE" || grep -qi "container.name\|container.id" "$RULE_FILE"; then
        echo -e "${GREEN}✓ Output includes container${NC}"
    else
        echo -e "${RED}✗ Output should include container info${NC}"
        OUTPUT_OK=false
    fi

    if grep -qi "k8s.pod.name\|pod=" "$RULE_FILE"; then
        echo -e "${GREEN}✓ Output includes pod name${NC}"
    else
        echo -e "${RED}✗ Output should include pod name (k8s.pod.name)${NC}"
        OUTPUT_OK=false
    fi

    if grep -qi "k8s.ns.name\|namespace=" "$RULE_FILE"; then
        echo -e "${GREEN}✓ Output includes namespace${NC}"
    else
        echo -e "${RED}✗ Output should include namespace (k8s.ns.name)${NC}"
        OUTPUT_OK=false
    fi

    if [ "$OUTPUT_OK" == "false" ]; then
        PASS=false
    fi
fi

# Check container ID saved (on node01)
if [ -f "/opt/course/13/container-id.txt" ]; then
    echo -e "${GREEN}✓ Container ID saved${NC}"
else
    echo -e "${RED}✗ Container ID not found at /opt/course/13/container-id.txt${NC}"
    PASS=false
fi

# Check falco alert log (on node01)
if [ -f "/opt/course/13/falco-alert.txt" ]; then
    echo -e "${GREEN}✓ Falco alert log saved${NC}"
else
    echo -e "${RED}✗ Falco alert log not found at /opt/course/13/falco-alert.txt${NC}"
    PASS=false
fi

if $PASS; then
    exit 0
else
    exit 1
fi
REMOTE_SCRIPT

exit $?
