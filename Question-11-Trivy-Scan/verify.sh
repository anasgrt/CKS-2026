#!/bin/bash
# Verify Question 11 - Trivy Scan

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking Trivy scan results..."
echo ""

# Check nginx 1.19 scan
if [ -f "/opt/course/11/nginx-1.19-scan.txt" ]; then
    echo -e "${GREEN}✓ nginx-1.19-scan.txt saved${NC}"
    if grep -qi "nginx\|vulnerability\|cve\|total" /opt/course/11/nginx-1.19-scan.txt; then
        echo -e "${GREEN}✓ nginx 1.19 scan appears to have valid content${NC}"
    else
        echo -e "${RED}✗ nginx 1.19 scan file seems empty or invalid${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ nginx-1.19-scan.txt not found${NC}"
    PASS=false
fi

# Check nginx 1.25-alpine scan
if [ -f "/opt/course/11/nginx-1.25-alpine-scan.txt" ]; then
    echo -e "${GREEN}✓ nginx-1.25-alpine-scan.txt saved${NC}"
    if grep -qi "nginx\|vulnerability\|cve\|total" /opt/course/11/nginx-1.25-alpine-scan.txt; then
        echo -e "${GREEN}✓ nginx 1.25-alpine scan appears to have valid content${NC}"
    fi
else
    echo -e "${RED}✗ nginx-1.25-alpine-scan.txt not found${NC}"
    PASS=false
fi

# Check python 3.8 scan
if [ -f "/opt/course/11/python-3.8-scan.txt" ]; then
    echo -e "${GREEN}✓ python-3.8-scan.txt saved${NC}"
    if grep -qi "python\|vulnerability\|cve\|total" /opt/course/11/python-3.8-scan.txt; then
        echo -e "${GREEN}✓ python 3.8 scan appears to have valid content${NC}"
    fi
else
    echo -e "${RED}✗ python-3.8-scan.txt not found${NC}"
    PASS=false
fi

# Check python 3.12-alpine scan
if [ -f "/opt/course/11/python-3.12-alpine-scan.txt" ]; then
    echo -e "${GREEN}✓ python-3.12-alpine-scan.txt saved${NC}"
    if grep -qi "python\|vulnerability\|cve\|total" /opt/course/11/python-3.12-alpine-scan.txt; then
        echo -e "${GREEN}✓ python 3.12-alpine scan appears to have valid content${NC}"
    fi
else
    echo -e "${RED}✗ python-3.12-alpine-scan.txt not found${NC}"
    PASS=false
fi

# Check recommendations file
echo ""
echo "Checking recommendations..."
if [ -f "/opt/course/11/recommendations.txt" ]; then
    echo -e "${GREEN}✓ recommendations.txt exists${NC}"

    # Check for nginx recommendation
    if grep -qi "nginx" /opt/course/11/recommendations.txt; then
        echo -e "${GREEN}✓ Contains nginx recommendation${NC}"
    else
        echo -e "${RED}✗ Missing nginx recommendation${NC}"
        PASS=false
    fi

    # Check for python recommendation
    if grep -qi "python" /opt/course/11/recommendations.txt; then
        echo -e "${GREEN}✓ Contains python recommendation${NC}"
    else
        echo -e "${RED}✗ Missing python recommendation${NC}"
        PASS=false
    fi

    # Check for vulnerability counts
    if grep -qiE "(high|critical|vulnerabilit|count|total)" /opt/course/11/recommendations.txt; then
        echo -e "${GREEN}✓ Contains vulnerability analysis${NC}"
    else
        echo -e "${RED}✗ Missing vulnerability counts/analysis${NC}"
        PASS=false
    fi

    # Check for reasoning (alpine usually recommended)
    if grep -qi "alpine\|fewer\|safer\|less\|recommend" /opt/course/11/recommendations.txt; then
        echo -e "${GREEN}✓ Contains reasoning for recommendations${NC}"
    else
        echo -e "${RED}✗ Should explain WHY images are recommended${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ recommendations.txt not found${NC}"
    PASS=false
fi

# Check if deployment was updated with safer images
echo ""
echo "Checking deployment update..."
if kubectl get deployment web-app -n trivy-test &>/dev/null; then
    NGINX_IMAGE=$(kubectl get deployment web-app -n trivy-test -o jsonpath='{.spec.template.spec.containers[?(@.name=="nginx")].image}')
    PYTHON_IMAGE=$(kubectl get deployment web-app -n trivy-test -o jsonpath='{.spec.template.spec.containers[?(@.name=="python")].image}')

    if [[ "$NGINX_IMAGE" == *"alpine"* ]]; then
        echo -e "${GREEN}✓ nginx updated to alpine variant${NC}"
    else
        echo -e "${RED}✗ nginx should be updated to alpine variant (safer)${NC}"
        PASS=false
    fi

    if [[ "$PYTHON_IMAGE" == *"alpine"* ]] || [[ "$PYTHON_IMAGE" == *"3.12"* ]]; then
        echo -e "${GREEN}✓ python updated to newer/alpine variant${NC}"
    else
        echo -e "${RED}✗ python should be updated to newer/alpine variant (safer)${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Deployment 'web-app' not found in trivy-test namespace${NC}"
    PASS=false
fi

# Check updated deployment YAML saved
if [ -f "/opt/course/11/updated-deployment.yaml" ]; then
    echo -e "${GREEN}✓ updated-deployment.yaml saved${NC}"
else
    echo -e "${RED}✗ updated-deployment.yaml not found${NC}"
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
