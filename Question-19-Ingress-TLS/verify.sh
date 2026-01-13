#!/bin/bash
# Verify Question 19 - Ingress TLS

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking Ingress TLS configuration..."
echo ""

# Check namespace
if kubectl get namespace web-ns &>/dev/null; then
    echo -e "${GREEN}✓ Namespace 'web-ns' exists${NC}"
else
    echo -e "${RED}✗ Namespace 'web-ns' not found${NC}"
    PASS=false
fi

# Check TLS secret
if kubectl get secret web-tls-secret -n web-ns &>/dev/null; then
    echo -e "${GREEN}✓ TLS secret 'web-tls-secret' exists${NC}"

    SECRET_TYPE=$(kubectl get secret web-tls-secret -n web-ns -o jsonpath='{.type}')
    if [ "$SECRET_TYPE" == "kubernetes.io/tls" ]; then
        echo -e "${GREEN}✓ Secret is type kubernetes.io/tls${NC}"
    else
        echo -e "${RED}✗ Secret should be type kubernetes.io/tls${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ TLS secret 'web-tls-secret' not found${NC}"
    PASS=false
fi

# Check Ingress
if kubectl get ingress secure-ingress -n web-ns &>/dev/null; then
    echo -e "${GREEN}✓ Ingress 'secure-ingress' exists${NC}"

    # Check TLS configuration
    TLS_SECRET=$(kubectl get ingress secure-ingress -n web-ns -o jsonpath='{.spec.tls[0].secretName}')
    if [ "$TLS_SECRET" == "web-tls-secret" ]; then
        echo -e "${GREEN}✓ Ingress uses 'web-tls-secret'${NC}"
    else
        echo -e "${RED}✗ Ingress should use 'web-tls-secret'${NC}"
        PASS=false
    fi

    # Check host
    HOST=$(kubectl get ingress secure-ingress -n web-ns -o jsonpath='{.spec.rules[0].host}')
    if [ "$HOST" == "secure.example.com" ]; then
        echo -e "${GREEN}✓ Host is 'secure.example.com'${NC}"
    else
        echo -e "${RED}✗ Host should be 'secure.example.com'${NC}"
        PASS=false
    fi

    # Check service backend
    SVC=$(kubectl get ingress secure-ingress -n web-ns -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')
    if [ "$SVC" == "web-svc" ]; then
        echo -e "${GREEN}✓ Backend service is 'web-svc'${NC}"
    else
        echo -e "${RED}✗ Backend should be 'web-svc'${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Ingress 'secure-ingress' not found${NC}"
    PASS=false
fi

# Check files saved
echo ""
echo "Checking saved files..."
if [ -f "/opt/course/19/ingress.yaml" ]; then
    echo -e "${GREEN}✓ Ingress YAML saved${NC}"
else
    echo -e "${RED}✗ Ingress YAML not found at /opt/course/19/ingress.yaml${NC}"
    PASS=false
fi

if [ -f "/opt/course/19/secret-create.txt" ]; then
    echo -e "${GREEN}✓ Secret creation command saved${NC}"
else
    echo -e "${RED}✗ secret-create.txt not found${NC}"
    PASS=false
fi

if [ -f "/opt/course/19/tls-verify.txt" ]; then
    echo -e "${GREEN}✓ TLS verification saved${NC}"
else
    echo -e "${RED}✗ tls-verify.txt not found${NC}"
    PASS=false
fi

if $PASS; then
    exit 0
else
    exit 1
fi
