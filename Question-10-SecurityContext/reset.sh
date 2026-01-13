#!/bin/bash
# Reset Question 10 - SecurityContext

kubectl delete pod hardened-pod -n hardened-ns --ignore-not-found
kubectl delete namespace hardened-ns --ignore-not-found
rm -rf /opt/course/10

echo "Question 10 reset complete!"
