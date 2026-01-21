#!/bin/bash
# Setup for Question 11 - Trivy Scan

set -e

# Create output directory
mkdir -p /opt/course/11

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
echo ""
echo "Basic Trivy commands:"
echo "  trivy image <image>                    # Full scan"
echo "  trivy image --severity HIGH,CRITICAL   # Filter by severity"
echo "  trivy image -f json                    # JSON output"
echo ""
echo "Severity levels: UNKNOWN, LOW, MEDIUM, HIGH, CRITICAL"
