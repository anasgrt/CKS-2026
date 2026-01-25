#!/bin/bash
# Reset Question 01 - NetworkPolicy Default Deny

set -e

kubectl delete networkpolicy default-deny-all -n isolated-ns --ignore-not-found
# Delete pods created by setup and user (test-pod is created by user per question)
kubectl delete pod web-server api-server test-pod -n isolated-ns --ignore-not-found
kubectl delete namespace isolated-ns --ignore-not-found
rm -rf /opt/course/01

echo "Question 01 reset complete!"
