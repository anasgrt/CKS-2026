#!/bin/bash
# Reset Question 09 - Secrets Encryption

kubectl delete secret test-secret -n secrets-ns --ignore-not-found
kubectl delete namespace secrets-ns --ignore-not-found
rm -rf /opt/course/09

echo "Question 09 reset complete!"
echo "Note: API server encryption configuration must be manually reverted."
