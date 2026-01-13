#!/bin/bash
# Reset Question 05 - ServiceAccount Security

kubectl delete rolebinding restricted-sa-binding -n secure-ns --ignore-not-found
kubectl delete role pod-reader -n secure-ns --ignore-not-found
kubectl delete serviceaccount restricted-sa -n secure-ns --ignore-not-found
kubectl delete deployment insecure-app -n secure-ns --ignore-not-found
kubectl delete namespace secure-ns --ignore-not-found
rm -rf /opt/course/05

echo "Question 05 reset complete!"
