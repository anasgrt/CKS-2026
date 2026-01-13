#!/bin/bash
# Reset Question 07 - Seccomp

kubectl delete pod runtime-default-pod custom-seccomp-pod -n seccomp-ns --ignore-not-found
kubectl delete namespace seccomp-ns --ignore-not-found
rm -rf /opt/course/07

echo "Question 07 reset complete!"
