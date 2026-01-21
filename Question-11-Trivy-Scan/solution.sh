#!/bin/bash
# Solution for Question 11 - Trivy Scan

echo "Solution: Scan images with Trivy"
echo ""
echo "Step 1: Scan all images and save results"
echo ""

cat << 'EOF'
trivy image --severity HIGH,CRITICAL nginx:1.19 > /opt/course/11/nginx-1.19-scan.txt 2>&1
trivy image --severity HIGH,CRITICAL nginx:1.25-alpine > /opt/course/11/nginx-1.25-alpine-scan.txt 2>&1
trivy image --severity HIGH,CRITICAL python:3.8 > /opt/course/11/python-3.8-scan.txt 2>&1
trivy image --severity HIGH,CRITICAL python:3.12-alpine > /opt/course/11/python-3.12-alpine-scan.txt 2>&1
EOF

echo ""
echo "Step 2: Count vulnerabilities for comparison"
echo ""

cat << 'EOF'
# Count vulnerabilities for each image
echo "nginx:1.19: $(grep -cE 'HIGH|CRITICAL' /opt/course/11/nginx-1.19-scan.txt)"
echo "nginx:1.25-alpine: $(grep -cE 'HIGH|CRITICAL' /opt/course/11/nginx-1.25-alpine-scan.txt)"
echo "python:3.8: $(grep -cE 'HIGH|CRITICAL' /opt/course/11/python-3.8-scan.txt)"
echo "python:3.12-alpine: $(grep -cE 'HIGH|CRITICAL' /opt/course/11/python-3.12-alpine-scan.txt)"
EOF

echo ""
echo "Step 3: Create recommendations.txt based on scan results"
echo ""

cat << 'EOF'
# Get counts
NGINX_119=$(grep -cE 'HIGH|CRITICAL' /opt/course/11/nginx-1.19-scan.txt || echo 0)
NGINX_125=$(grep -cE 'HIGH|CRITICAL' /opt/course/11/nginx-1.25-alpine-scan.txt || echo 0)
PYTHON_38=$(grep -cE 'HIGH|CRITICAL' /opt/course/11/python-3.8-scan.txt || echo 0)
PYTHON_312=$(grep -cE 'HIGH|CRITICAL' /opt/course/11/python-3.12-alpine-scan.txt || echo 0)

# Compare nginx images
if [ "$NGINX_125" -le "$NGINX_119" ]; then
    BEST_NGINX="nginx:1.25-alpine"
else
    BEST_NGINX="nginx:1.19"
fi

# Compare python images
if [ "$PYTHON_312" -le "$PYTHON_38" ]; then
    BEST_PYTHON="python:3.12-alpine"
else
    BEST_PYTHON="python:3.8"
fi

# Write recommendations
cat > /opt/course/11/recommendations.txt << REC
Recommended nginx image: $BEST_NGINX
- nginx:1.19 HIGH/CRITICAL: $NGINX_119
- nginx:1.25-alpine HIGH/CRITICAL: $NGINX_125

Recommended python image: $BEST_PYTHON
- python:3.8 HIGH/CRITICAL: $PYTHON_38
- python:3.12-alpine HIGH/CRITICAL: $PYTHON_312
REC
EOF

echo ""
echo "Step 4: Update deployment with recommended images"
echo ""

cat << 'EOF'
# Update deployment (use the recommended images from Step 3)
kubectl set image deployment/web-app \
  nginx=$BEST_NGINX \
  python=$BEST_PYTHON \
  -n trivy-test

kubectl get deployment web-app -n trivy-test -o yaml > /opt/course/11/updated-deployment.yaml
EOF

echo ""
echo "Key Points:"
echo "- Compare actual vulnerability counts, don't assume"
echo "- Document your findings with specific numbers"
echo "- Update deployment with the safer images"
