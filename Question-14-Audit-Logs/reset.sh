#!/bin/bash
# Reset Question 14 - Audit Logs

# Delete secret created by user (question uses audit-test namespace)
kubectl delete secret test-secret -n audit-test --ignore-not-found
kubectl delete namespace audit-test --ignore-not-found
rm -rf /opt/course/14

echo "Question 14 reset complete!"
echo "Note: API server audit configuration must be manually reverted."
echo "      Remove --audit-* flags from kube-apiserver manifest."
