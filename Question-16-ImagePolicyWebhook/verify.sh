#!/bin/bash
# Verify Question 16 - ImagePolicyWebhook
# Based on real CKS exam patterns (2025/2026)

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=true
SCORE=0
TOTAL=8

echo "=============================================="
echo "Verifying ImagePolicyWebhook Configuration"
echo "=============================================="
echo ""

# Check 1: kubeconf.yaml exists and has required content
echo "Check 1: Kubeconfig file structure"
if [ -f "/etc/kubernetes/admission/kubeconf.yaml" ]; then
    # Check for cluster server URL
    if grep -q "server:.*https://image-bouncer-webhook.default.svc:1323/image_policy" /etc/kubernetes/admission/kubeconf.yaml 2>/dev/null; then
        echo -e "${GREEN}✓ Server URL is correctly configured${NC}"
        ((SCORE++))
    else
        echo -e "${RED}✗ Server URL should be: https://image-bouncer-webhook.default.svc:1323/image_policy${NC}"
        PASS=false
    fi

    # Check for certificate-authority
    if grep -q "certificate-authority:.*external-cert.pem" /etc/kubernetes/admission/kubeconf.yaml 2>/dev/null; then
        echo -e "${GREEN}✓ Certificate authority is configured${NC}"
        ((SCORE++))
    else
        echo -e "${RED}✗ Certificate authority should reference external-cert.pem${NC}"
        PASS=false
    fi

    # Check for current-context (CRITICAL!)
    if grep -q "current-context:.*image-checker" /etc/kubernetes/admission/kubeconf.yaml 2>/dev/null; then
        echo -e "${GREEN}✓ current-context is set to image-checker${NC}"
        ((SCORE++))
    else
        echo -e "${RED}✗ current-context MUST be set to 'image-checker' (common exam mistake!)${NC}"
        PASS=false
    fi

    # Check for client certificate and key
    if grep -q "client-certificate:.*apiserver-client-cert.pem" /etc/kubernetes/admission/kubeconf.yaml 2>/dev/null && \
       grep -q "client-key:.*apiserver-client-key.pem" /etc/kubernetes/admission/kubeconf.yaml 2>/dev/null; then
        echo -e "${GREEN}✓ Client certificate and key are configured${NC}"
        ((SCORE++))
    else
        echo -e "${RED}✗ Client certificate and key should be configured for user 'api-server'${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Kubeconfig file not found at /etc/kubernetes/admission/kubeconf.yaml${NC}"
    PASS=false
fi

echo ""

# Check 2: admission_config.yaml has required content
echo "Check 2: Admission configuration"
if [ -f "/etc/kubernetes/admission/admission_config.yaml" ]; then
    if grep -q "ImagePolicyWebhook" /etc/kubernetes/admission/admission_config.yaml; then
        echo -e "${GREEN}✓ Contains ImagePolicyWebhook plugin${NC}"
    else
        echo -e "${RED}✗ Should contain ImagePolicyWebhook plugin${NC}"
        PASS=false
    fi

    if grep -q "kubeConfigFile:.*kubeconf.yaml" /etc/kubernetes/admission/admission_config.yaml 2>/dev/null; then
        echo -e "${GREEN}✓ kubeConfigFile references kubeconf.yaml${NC}"
        ((SCORE++))
    else
        echo -e "${RED}✗ kubeConfigFile should reference the kubeconf.yaml file${NC}"
        PASS=false
    fi

    if grep -qE "defaultAllow:\s*(false|False)" /etc/kubernetes/admission/admission_config.yaml 2>/dev/null; then
        echo -e "${GREEN}✓ defaultAllow is set to false (fail-closed mode)${NC}"
        ((SCORE++))
    else
        echo -e "${RED}✗ defaultAllow MUST be false for fail-closed security${NC}"
        PASS=false
    fi

    # Check for TTL and retry settings
    if grep -q "allowTTL:" /etc/kubernetes/admission/admission_config.yaml 2>/dev/null && \
       grep -q "denyTTL:" /etc/kubernetes/admission/admission_config.yaml 2>/dev/null && \
       grep -q "retryBackoff:" /etc/kubernetes/admission/admission_config.yaml 2>/dev/null; then
        echo -e "${GREEN}✓ TTL and retry settings are configured${NC}"
    else
        echo -e "${YELLOW}⚠ TTL/retry settings (allowTTL, denyTTL, retryBackoff) may be missing${NC}"
    fi
else
    echo -e "${RED}✗ Admission configuration not found${NC}"
    PASS=false
fi

echo ""

# Check 3: API server configuration
echo "Check 3: API server configuration"
if [ -f "/etc/kubernetes/manifests/kube-apiserver.yaml" ]; then
    if grep -q "ImagePolicyWebhook" /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null; then
        echo -e "${GREEN}✓ ImagePolicyWebhook enabled in admission plugins${NC}"
        ((SCORE++))
    else
        echo -e "${RED}✗ ImagePolicyWebhook should be in --enable-admission-plugins${NC}"
        PASS=false
    fi

    if grep -q "admission-control-config-file" /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null; then
        echo -e "${GREEN}✓ admission-control-config-file flag is present${NC}"
        ((SCORE++))
    else
        echo -e "${RED}✗ --admission-control-config-file flag is missing${NC}"
        PASS=false
    fi

    # Check for runtime-config enabling imagepolicy API
    if grep -q "imagepolicy.k8s.io/v1alpha1=true" /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null; then
        echo -e "${GREEN}✓ imagepolicy.k8s.io/v1alpha1 API is enabled${NC}"
    else
        echo -e "${YELLOW}⚠ imagepolicy.k8s.io/v1alpha1 may need to be enabled in --runtime-config${NC}"
    fi

    # Check for volume mount
    if grep -q "/etc/kubernetes/admission" /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null; then
        echo -e "${GREEN}✓ Admission directory appears to be mounted${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: /etc/kubernetes/admission volume mount may be missing${NC}"
    fi
else
    echo -e "${RED}✗ API server manifest not found${NC}"
    PASS=false
fi

echo ""

# Check 4: Saved copies in /opt/course/16/
echo "Check 4: Files saved to /opt/course/16/"
if [ -f "/opt/course/16/admission_config.yaml" ]; then
    echo -e "${GREEN}✓ admission_config.yaml saved to /opt/course/16/${NC}"
else
    echo -e "${RED}✗ admission_config.yaml not found in /opt/course/16/${NC}"
    PASS=false
fi

if [ -f "/opt/course/16/kubeconf.yaml" ]; then
    echo -e "${GREEN}✓ kubeconf.yaml saved to /opt/course/16/${NC}"
else
    echo -e "${RED}✗ kubeconf.yaml not found in /opt/course/16/${NC}"
    PASS=false
fi

echo ""

# Check 5: API server responsiveness
echo "Check 5: API server status"
if kubectl get nodes &>/dev/null; then
    echo -e "${GREEN}✓ API server is responding${NC}"
else
    echo -e "${YELLOW}⚠ API server is not responding - may still be restarting${NC}"
    echo "   Wait 30-60 seconds and try again"
    echo "   You can check container status with: crictl ps | grep apiserver"
fi

echo ""
echo "=============================================="
echo "Score: $SCORE out of $TOTAL key checks passed"
echo "=============================================="
echo ""

if $PASS; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo ""
    echo "Note: Even with correct configuration, pod creation will fail with"
    echo "'webhook unavailable' error because there's no actual webhook service."
    echo "This is expected and confirms defaultAllow: false is working."
    exit 0
else
    echo -e "${RED}✗ Some checks failed - review the issues above${NC}"
    echo ""
    echo "Common issues:"
    echo "  1. Forgetting to set current-context in kubeconf.yaml"
    echo "  2. Wrong path in kubeConfigFile reference"
    echo "  3. defaultAllow not set to false"
    echo "  4. Missing volume mount for admission directory"
    echo "  5. YAML syntax errors (use 'cat <file>' to verify)"
    exit 1
fi
