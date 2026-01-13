#!/bin/bash
# Solution for Question 11 - Trivy Scan

echo "Solution: Scan images with Trivy"
echo ""
echo "Step 1: Scan nginx image"
echo ""

cat << 'EOF'
trivy image --severity HIGH,CRITICAL nginx:1.19 > /opt/course/11/nginx-scan.txt 2>&1
EOF

echo ""
echo "Step 2: Scan python image"
echo ""

cat << 'EOF'
trivy image --severity HIGH,CRITICAL python:3.8-alpine > /opt/course/11/python-scan.txt 2>&1
EOF

echo ""
echo "Step 3: Analyze results and create safe-images.txt"
echo ""

cat << 'EOF'
# Count HIGH/CRITICAL vulnerabilities
NGINX_COUNT=$(grep -c "HIGH\|CRITICAL" /opt/course/11/nginx-scan.txt || echo "0")
PYTHON_COUNT=$(grep -c "HIGH\|CRITICAL" /opt/course/11/python-scan.txt || echo "0")

echo "nginx:1.19 vulnerabilities: $NGINX_COUNT"
echo "python:3.8-alpine vulnerabilities: $PYTHON_COUNT"

# Create safe-images.txt with the image that has fewer vulnerabilities
if [ "$PYTHON_COUNT" -lt "$NGINX_COUNT" ]; then
    echo "python:3.8-alpine" > /opt/course/11/safe-images.txt
else
    echo "nginx:1.19" > /opt/course/11/safe-images.txt
fi
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
