#!/bin/bash
# Reset Question 11 - Trivy Scan

# Delete deployment updated by user
kubectl delete deployment web-app -n trivy-test --ignore-not-found
# Delete namespace created by setup
kubectl delete namespace trivy-test --ignore-not-found

rm -rf /opt/course/11

echo "Question 11 reset complete!"
