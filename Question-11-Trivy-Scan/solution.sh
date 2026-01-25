#!/bin/bash
# Solution for Question 11 - Trivy Scan

echo "=== Step 1: Scan All Images ==="
echo "trivy image --severity HIGH,CRITICAL nginx:1.19 > /opt/course/11/nginx-1.19-scan.txt"
echo "trivy image --severity HIGH,CRITICAL nginx:1.25-alpine > /opt/course/11/nginx-1.25-alpine-scan.txt"
echo "trivy image --severity HIGH,CRITICAL python:3.8 > /opt/course/11/python-3.8-scan.txt"
echo "trivy image --severity HIGH,CRITICAL python:3.12-alpine > /opt/course/11/python-3.12-alpine-scan.txt"
echo ""

echo "=== Step 2: Count Vulnerabilities ==="
echo "grep -c HIGH /opt/course/11/nginx-1.19-scan.txt"
echo "grep -c HIGH /opt/course/11/nginx-1.25-alpine-scan.txt"
echo "grep -c HIGH /opt/course/11/python-3.8-scan.txt"
echo "grep -c HIGH /opt/course/11/python-3.12-alpine-scan.txt"
echo ""

echo "=== Step 3: Write Recommendations ==="
cat << 'EOF'
cat > /opt/course/11/recommendations.txt << 'TXT'
Recommended nginx: nginx:1.25-alpine
- nginx:1.19 has more vulnerabilities (older, full image)
- nginx:1.25-alpine has fewer (newer, minimal alpine base)

Recommended python: python:3.12-alpine
- python:3.8 has more vulnerabilities (older, full image)
- python:3.12-alpine has fewer (newer, minimal alpine base)

Alpine images are smaller and have fewer packages = fewer vulnerabilities.
TXT
EOF
echo ""

echo "=== Step 4: Update Deployment ==="
echo "kubectl set image deployment/web-app nginx=nginx:1.25-alpine python=python:3.12-alpine -n trivy-test"
echo "kubectl get deployment web-app -n trivy-test -o yaml > /opt/course/11/updated-deployment.yaml"
echo ""
echo "Key: Alpine images = smaller = fewer vulnerabilities. Always use specific tags, not 'latest'."
