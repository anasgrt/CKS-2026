#!/bin/bash
# Reset Question 18 - Node Metadata Protection

kubectl delete networkpolicy block-metadata -n protected-ns --ignore-not-found
# Delete test pods (test-pod and test-metadata are mentioned in solution)
kubectl delete pod test-pod test-metadata -n protected-ns --ignore-not-found
kubectl delete namespace protected-ns --ignore-not-found
rm -rf /opt/course/18

echo "Question 18 reset complete!"
