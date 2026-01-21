#!/bin/bash
# Solution for Question 11 - Trivy Scan

echo "Solution: Scan images with Trivy"
echo ""
echo "Step 1: Scan all four images"
echo ""

cat << 'EOF'
# Scan nginx images
trivy image --severity HIGH,CRITICAL nginx:1.19 > /opt/course/11/nginx-1.19-scan.txt 2>&1
trivy image --severity HIGH,CRITICAL nginx:1.25-alpine > /opt/course/11/nginx-1.25-alpine-scan.txt 2>&1

# Scan python images
trivy image --severity HIGH,CRITICAL python:3.8 > /opt/course/11/python-3.8-scan.txt 2>&1
trivy image --severity HIGH,CRITICAL python:3.12-alpine > /opt/course/11/python-3.12-alpine-scan.txt 2>&1
EOF

echo ""
echo "Step 2: Analyze results and count vulnerabilities"
echo ""

cat << 'EOF'
# Count HIGH/CRITICAL vulnerabilities for nginx images
NGINX_119_COUNT=$(grep -cE "HIGH|CRITICAL" /opt/course/11/nginx-1.19-scan.txt || echo "0")
NGINX_125_ALPINE_COUNT=$(grep -cE "HIGH|CRITICAL" /opt/course/11/nginx-1.25-alpine-scan.txt || echo "0")

# Count HIGH/CRITICAL vulnerabilities for python images
PYTHON_38_COUNT=$(grep -cE "HIGH|CRITICAL" /opt/course/11/python-3.8-scan.txt || echo "0")
PYTHON_312_ALPINE_COUNT=$(grep -cE "HIGH|CRITICAL" /opt/course/11/python-3.12-alpine-scan.txt || echo "0")

echo "nginx:1.19 vulnerabilities: $NGINX_119_COUNT"
echo "nginx:1.25-alpine vulnerabilities: $NGINX_125_ALPINE_COUNT"
echo "python:3.8 vulnerabilities: $PYTHON_38_COUNT"
echo "python:3.12-alpine vulnerabilities: $PYTHON_312_ALPINE_COUNT"
EOF

echo ""
echo "Step 3: Create recommendations.txt"
echo ""

cat << 'EOF'
# Determine safer nginx image (compare nginx:1.19 vs nginx:1.25-alpine)
if [ "$NGINX_125_ALPINE_COUNT" -lt "$NGINX_119_COUNT" ]; then
    RECOMMENDED_NGINX="nginx:1.25-alpine"
    NGINX_REASON="fewer vulnerabilities and smaller attack surface (Alpine-based)"
else
    RECOMMENDED_NGINX="nginx:1.19"
    NGINX_REASON="fewer vulnerabilities"
fi

# Determine safer python image (compare python:3.8 vs python:3.12-alpine)
if [ "$PYTHON_312_ALPINE_COUNT" -lt "$PYTHON_38_COUNT" ]; then
    RECOMMENDED_PYTHON="python:3.12-alpine"
    PYTHON_REASON="fewer vulnerabilities and smaller attack surface (Alpine-based)"
else
    RECOMMENDED_PYTHON="python:3.8"
    PYTHON_REASON="fewer vulnerabilities"
fi

# Create recommendations file
cat > /opt/course/11/recommendations.txt << RECOMMENDATIONS
Recommended Images Analysis
===========================

NGINX:
- Recommended: $RECOMMENDED_NGINX
- Reason: $NGINX_REASON
- nginx:1.19 HIGH/CRITICAL count: $NGINX_119_COUNT
- nginx:1.25-alpine HIGH/CRITICAL count: $NGINX_125_ALPINE_COUNT

PYTHON:
- Recommended: $RECOMMENDED_PYTHON
- Reason: $PYTHON_REASON
- python:3.8 HIGH/CRITICAL count: $PYTHON_38_COUNT
- python:3.12-alpine HIGH/CRITICAL count: $PYTHON_312_ALPINE_COUNT

Note: Alpine-based images have smaller attack surface due to minimal base OS.
RECOMMENDATIONS
EOF

echo ""
echo "Step 4: Update deployment with safer images"
echo ""

cat << 'EOF'
# Get current deployment
kubectl get deployment web-app -n trivy-test -o yaml > /opt/course/11/updated-deployment.yaml

# Update images to safer versions (typically the alpine variants)
# Edit /opt/course/11/updated-deployment.yaml and replace:
#   - nginx:1.19 -> nginx:1.25-alpine
#   - python:3.8 -> python:3.12-alpine

# Or use kubectl set image
kubectl set image deployment/web-app \
  nginx=nginx:1.25-alpine \
  python=python:3.12-alpine \
  -n trivy-test

# Save updated deployment
kubectl get deployment web-app -n trivy-test -o yaml > /opt/course/11/updated-deployment.yaml
EOF

echo ""
echo "Useful Trivy options:"
echo "  --severity CRITICAL         Only show CRITICAL"
echo "  --ignore-unfixed           Ignore vulnerabilities without fixes"
echo "  -f json                    JSON output for scripting"
echo "  --exit-code 1              Exit with 1 if vulnerabilities found"
echo "  trivy image --input tar    Scan a tarball image"
echo ""
echo "Key Points:"
echo "- Use specific tags, never 'latest' in production"
echo "- Alpine images typically have fewer vulnerabilities"
echo "- Regularly rescan images as new CVEs are published"
echo "- Integrate Trivy into CI/CD pipelines"
