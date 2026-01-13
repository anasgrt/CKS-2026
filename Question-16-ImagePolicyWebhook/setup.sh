#!/bin/bash
# Setup for Question 16 - ImagePolicyWebhook

set -e

# Create output directory
mkdir -p /opt/course/16

echo "Environment ready!"
echo ""
echo "ImagePolicyWebhook verifies images against external policies."
echo ""
echo "Important paths:"
echo "  API server manifest: /etc/kubernetes/manifests/kube-apiserver.yaml"
echo "  Admission config: /etc/kubernetes/admission/"
echo "  Webhook CA cert: /etc/kubernetes/pki/image-policy-ca.crt"
echo ""
echo "API server flags needed:"
echo "  --enable-admission-plugins=ImagePolicyWebhook,..."
echo "  --admission-control-config-file=<path>"
