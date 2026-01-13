#!/bin/bash
# Setup for Question 08 - PSA Restricted

set -e

# Create output directory
mkdir -p /opt/course/08

echo "Environment ready!"
echo ""
echo "Pod Security Standards levels:"
echo "  - privileged: Unrestricted policy"
echo "  - baseline: Minimally restrictive, prevents known privilege escalations"
echo "  - restricted: Heavily restricted, following security best practices"
echo ""
echo "PSA modes:"
echo "  - enforce: Policy violations will cause pod rejection"
echo "  - audit: Policy violations trigger audit annotation"
echo "  - warn: Policy violations trigger user-facing warning"
