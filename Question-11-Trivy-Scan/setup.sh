#!/bin/bash
# Setup for Question 11 - Trivy Scan

set -e

# Create output directory
mkdir -p /opt/course/11

# Create namespace for deployment update
kubectl create namespace trivy-test --dry-run=client -o yaml | kubectl apply -f -

# Create the web-app deployment with older/vulnerable images
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: trivy-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.19
        ports:
        - containerPort: 80
      - name: python
        image: python:3.8
        command: ["python", "-m", "http.server", "8000"]
        ports:
        - containerPort: 8000
EOF

# Install Trivy if not already installed
if ! command -v trivy &> /dev/null; then
    echo "Installing Trivy..."
    # Add Trivy repository and install
    apt-get update -qq
    apt-get install -y -qq wget apt-transport-https gnupg lsb-release
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/trivy.list
    apt-get update -qq
    apt-get install -y -qq trivy
    echo "✓ Trivy installed successfully"
else
    echo "✓ Trivy already installed"
fi

echo ""
echo "Environment ready!"
echo ""
echo "Trivy is installed at: $(which trivy)"
echo "Namespace: trivy-test"
echo "Deployment: web-app (using nginx:1.19 and python:3.8 - older images)"
echo ""
echo "Basic Trivy commands:"
echo "  trivy image <image>                    # Full scan"
echo "  trivy image --severity HIGH,CRITICAL   # Filter by severity"
echo "  trivy image -f json                    # JSON output"
echo ""
echo "Severity levels: UNKNOWN, LOW, MEDIUM, HIGH, CRITICAL"
