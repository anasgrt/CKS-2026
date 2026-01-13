#!/bin/bash
# Reset Question 01 - NetworkPolicy Default Deny

set -e

kubectl delete networkpolicy default-deny-all -n isolated-ns --ignore-not-found
kubectl delete pod web-server api-server -n isolated-ns --ignore-not-found
kubectl delete namespace isolated-ns --ignore-not-found
rm -rf /opt/course/01

echo "Question 01 reset complete!"
