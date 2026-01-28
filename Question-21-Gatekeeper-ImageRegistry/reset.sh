#!/bin/bash
# Reset Question 21 - Gatekeeper Image Registry Restriction
# Based on real CKS exam patterns (2025/2026)

echo "Resetting Gatekeeper Image Registry Restriction scenario..."
echo ""

# Remove output directory
rm -rf /opt/course/21

# Delete the constraint first (must be deleted before template)
echo "Deleting Constraint 'allowed-repos'..."
kubectl delete k8sallowedrepos allowed-repos --ignore-not-found=true 2>/dev/null

# Wait a moment for cleanup
sleep 2

# Delete the constraint template
echo "Deleting ConstraintTemplate 'k8sallowedrepos'..."
kubectl delete constrainttemplate k8sallowedrepos --ignore-not-found=true 2>/dev/null

# Delete test pods
echo "Cleaning up test pods..."
kubectl delete pod -n gatekeeper-test --all --ignore-not-found=true 2>/dev/null

# Clean up any test pods that might have been created in default namespace
kubectl delete pod test-allowed -n default --ignore-not-found=true 2>/dev/null
kubectl delete pod test-disallowed -n default --ignore-not-found=true 2>/dev/null
kubectl delete pod allowed-nginx -n default --ignore-not-found=true 2>/dev/null
kubectl delete pod disallowed-app -n default --ignore-not-found=true 2>/dev/null

# Delete test namespace
echo "Deleting test namespace..."
kubectl delete namespace gatekeeper-test --ignore-not-found=true 2>/dev/null

echo ""
echo "=============================================="
echo "Reset complete!"
echo "=============================================="
echo ""
echo "NOTE: Gatekeeper itself is NOT removed (it may be used by other questions)."
echo "Only the custom ConstraintTemplate, Constraint, and test resources were removed."
echo ""
echo "To completely remove Gatekeeper, run:"
echo "  kubectl delete -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.14.0/deploy/gatekeeper.yaml"
