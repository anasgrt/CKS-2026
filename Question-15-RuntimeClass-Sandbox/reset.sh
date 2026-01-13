#!/bin/bash
# Reset Question 15 - RuntimeClass Sandbox

kubectl delete pod sandboxed-pod -n sandbox-ns --ignore-not-found
kubectl delete namespace sandbox-ns --ignore-not-found
rm -rf /opt/course/15

echo "Question 15 reset complete!"
