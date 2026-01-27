#!/bin/bash
# Verify Question 16 - ImagePolicyWebhook

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true

echo "Checking ImagePolicyWebhook configuration..."
echo ""

# Check admission config
if [ -f "/opt/course/16/admission-config.yaml" ]; then
    echo -e "${GREEN}✓ Admission configuration file exists${NC}"

    if grep -q "ImagePolicyWebhook" /opt/course/16/admission-config.yaml; then
        echo -e "${GREEN}✓ Contains ImagePolicyWebhook configuration${NC}"
    else
        echo -e "${RED}✗ Should contain ImagePolicyWebhook configuration${NC}"
        PASS=false
    fi

    if grep -q "defaultAllow.*false" /opt/course/16/admission-config.yaml; then
        echo -e "${GREEN}✓ defaultAllow set to false${NC}"
    else
        echo -e "${RED}✗ defaultAllow should be false${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Admission configuration not found${NC}"
    PASS=false
fi

# Check kubeconfig
if [ -f "/opt/course/16/image-policy-kubeconfig.yaml" ]; then
    echo -e "${GREEN}✓ Webhook kubeconfig exists${NC}"

    if grep -q "image-policy-webhook.image-policy" /opt/course/16/image-policy-kubeconfig.yaml; then
        echo -e "${GREEN}✓ Kubeconfig points to webhook service${NC}"
    else
        echo -e "${RED}✗ Kubeconfig should point to image-policy-webhook.image-policy service${NC}"
        PASS=false
    fi

    if grep -q "name: api-server" /opt/course/16/image-policy-kubeconfig.yaml; then
        echo -e "${GREEN}✓ Kubeconfig has user 'api-server' configured${NC}"
    else
        echo -e "${RED}✗ Kubeconfig should have user 'api-server' configured${NC}"
        PASS=false
    fi

    if grep -q "client-certificate:" /opt/course/16/image-policy-kubeconfig.yaml && \
       grep -q "client-key:" /opt/course/16/image-policy-kubeconfig.yaml; then
        echo -e "${GREEN}✓ Kubeconfig has client certificate and key configured${NC}"
    else
        echo -e "${RED}✗ Kubeconfig should have client-certificate and client-key configured${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Webhook kubeconfig not found${NC}"
    PASS=false
fi

# Check policy test results
if [ -f "/opt/course/16/policy-test.txt" ]; then
    echo -e "${GREEN}✓ Policy test results saved${NC}"
else
    echo -e "${RED}✗ Policy test results not found at /opt/course/16/policy-test.txt${NC}"
    PASS=false
fi

if $PASS; then
    exit 0
else
    exit 1
fi
