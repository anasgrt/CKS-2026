#!/bin/bash
# Setup for Question 11 - Trivy Scan

set -e

# Create output directory
mkdir -p /opt/course/11

echo "Environment ready!"
echo ""
echo "Trivy is installed at: /usr/local/bin/trivy"
echo ""
echo "Basic Trivy commands:"
echo "  trivy image <image>                    # Full scan"
echo "  trivy image --severity HIGH,CRITICAL   # Filter by severity"
echo "  trivy image -f json                    # JSON output"
echo ""
echo "Severity levels: UNKNOWN, LOW, MEDIUM, HIGH, CRITICAL"
