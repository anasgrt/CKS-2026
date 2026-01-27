#!/bin/bash
# Setup for Question 16 - ImagePolicyWebhook
# Based on real CKS exam patterns (2025/2026)

set -e

echo "Setting up ImagePolicyWebhook scenario..."

# Create output directory
sudo mkdir -p /opt/course/16

# Create admission directory
sudo mkdir -p /etc/kubernetes/admission

# Create placeholder certificate files (in real exam these would be actual certs)
# These simulate the pre-existing certificates the exam provides
sudo bash -c 'cat > /etc/kubernetes/admission/external-cert.pem << EOF
-----BEGIN CERTIFICATE-----
MIICyDCCAbCgAwIBAgIBADANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwptaW5p
a3ViZUNBMB4XDTIwMDEwMTAwMDAwMFoXDTMwMDEwMTAwMDAwMFowFTETMBEGA1UE
AxMKbWluaWt1YmVDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAN0G
placeholder-certificate-data-for-testing-purposes-only
-----END CERTIFICATE-----
EOF'

sudo bash -c 'cat > /etc/kubernetes/admission/apiserver-client-cert.pem << EOF
-----BEGIN CERTIFICATE-----
MIICyDCCAbCgAwIBAgIBADANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwptaW5p
a3ViZUNBMB4XDTIwMDEwMTAwMDAwMFoXDTMwMDEwMTAwMDAwMFowFTETMBEGA1UE
placeholder-client-certificate-for-testing-purposes-only
-----END CERTIFICATE-----
EOF'

sudo bash -c 'cat > /etc/kubernetes/admission/apiserver-client-key.pem << EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA3QZplaceholder-private-key-for-testing-purposes
placeholder-key-data-only-used-for-exam-simulation
-----END RSA PRIVATE KEY-----
EOF'

# Create incomplete kubeconfig file (candidate must complete it)
sudo bash -c 'cat > /etc/kubernetes/admission/kubeconf.yaml << EOF
# ImagePolicyWebhook Kubeconfig
# Complete this file to configure the webhook connection
apiVersion: v1
kind: Config

# TODO: Add cluster configuration
# - name: image-checker
# - server URL: https://image-bouncer-webhook.default.svc:1323/image_policy
# - certificate-authority: /etc/kubernetes/admission/external-cert.pem
clusters:
- cluster:
    # COMPLETE THIS SECTION
  name: image-checker

# TODO: Add context configuration
contexts:
- context:
    cluster: image-checker
    user: api-server
  name: image-checker

# TODO: Set the current context
current-context: ""

preferences: {}

# TODO: Add user configuration for api-server
# - client-certificate: /etc/kubernetes/admission/apiserver-client-cert.pem
# - client-key: /etc/kubernetes/admission/apiserver-client-key.pem
users:
- name: api-server
  user:
    # COMPLETE THIS SECTION
EOF'

# Create incomplete admission configuration file (candidate must complete it)
sudo bash -c 'cat > /etc/kubernetes/admission/admission_config.yaml << EOF
# AdmissionConfiguration for ImagePolicyWebhook
# Complete this file to enable the image policy webhook
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      # TODO: Add kubeConfigFile path
      # kubeConfigFile: <path-to-kubeconf.yaml>

      # TODO: Configure TTL and retry settings
      # allowTTL: 50
      # denyTTL: 50
      # retryBackoff: 500

      # TODO: Set defaultAllow to deny pods if webhook unreachable
      # defaultAllow: false
EOF'

echo ""
echo "=============================================="
echo "ImagePolicyWebhook Scenario Setup Complete"
echo "=============================================="
echo ""
echo "The scenario simulates a real CKS exam question where you need to:"
echo "  1. Complete the kubeconfig file at:"
echo "     /etc/kubernetes/admission/kubeconf.yaml"
echo ""
echo "  2. Complete the admission configuration at:"
echo "     /etc/kubernetes/admission/admission_config.yaml"
echo ""
echo "  3. Configure the API server to use ImagePolicyWebhook"
echo "     /etc/kubernetes/manifests/kube-apiserver.yaml"
echo ""
echo "Certificate files are pre-created at:"
echo "  - /etc/kubernetes/admission/external-cert.pem"
echo "  - /etc/kubernetes/admission/apiserver-client-cert.pem"
echo "  - /etc/kubernetes/admission/apiserver-client-key.pem"
echo ""
echo "Documentation reference:"
echo "  https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#imagepolicywebhook"
echo ""
echo "IMPORTANT: After modifying the API server manifest, wait 30-60 seconds"
echo "for the API server to restart. Use 'kubectl get nodes' to verify it's back."
echo ""
