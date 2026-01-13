#!/bin/bash
# Reset Question 18 - Node Metadata Protection

kubectl delete networkpolicy block-metadata -n protected-ns --ignore-not-found
kubectl delete pod test-pod -n protected-ns --ignore-not-found
kubectl delete namespace protected-ns --ignore-not-found
rm -rf /opt/course/18

echo "Question 18 reset complete!"
