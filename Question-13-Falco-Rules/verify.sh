#!/bin/bash
# Verify Question 13 - Falco Rules

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking Falco rule configuration..."
echo ""

# Check custom rule file exists (either in /etc/falco or local copy)
RULE_FILE=""
if [ -f "/etc/falco/rules.d/shell-detect.yaml" ]; then
    RULE_FILE="/etc/falco/rules.d/shell-detect.yaml"
    echo -e "${GREEN}✓ Custom rule file exists at /etc/falco/rules.d/shell-detect.yaml${NC}"
elif [ -f "/opt/course/13/shell-detect.yaml" ]; then
    RULE_FILE="/opt/course/13/shell-detect.yaml"
    echo -e "${GREEN}✓ Custom rule file exists at /opt/course/13/shell-detect.yaml${NC}"
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

    # Check output format
    if grep -q "user=" "$RULE_FILE" && grep -q "container=" "$RULE_FILE"; then
        echo -e "${GREEN}✓ Output format includes user and container${NC}"
    else
        echo -e "${RED}✗ Output should include user and container info${NC}"
        PASS=false
    fi
fi

# Check container ID saved
if [ -f "/opt/course/13/container-id.txt" ]; then
    echo -e "${GREEN}✓ Container ID saved${NC}"
else
    echo -e "${RED}✗ Container ID not found at /opt/course/13/container-id.txt${NC}"
    PASS=false
fi

# Check falco alert log
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
