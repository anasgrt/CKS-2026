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
if [ -f "/opt/course/11/recommendations.txt" ]; then
    echo -e "${GREEN}✓ recommendations.txt exists${NC}"
else
    echo -e "${RED}✗ recommendations.txt not found${NC}"
    PASS=false
fi

# Check updated deployment
if [ -f "/opt/course/11/updated-deployment.yaml" ]; then
    echo -e "${GREEN}✓ updated-deployment.yaml saved${NC}"
else
    echo -e "${RED}✗ updated-deployment.yaml not found${NC}"
    PASS=false
fi

# Check deployment uses updated images (if cluster access)
if kubectl get deployment web-app -n trivy-test &>/dev/null; then
    NGINX_IMAGE=$(kubectl get deployment web-app -n trivy-test -o jsonpath='{.spec.template.spec.containers[?(@.name=="nginx")].image}')
    if [[ "$NGINX_IMAGE" == *"alpine"* ]]; then
        echo -e "${GREEN}✓ Deployment uses alpine-based nginx image${NC}"
    else
        echo -e "${RED}✗ Deployment should use safer alpine-based image${NC}"
        PASS=false
    fi
fi

if $PASS; then
    exit 0
else
    exit 1
fi
