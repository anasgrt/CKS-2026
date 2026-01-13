#!/bin/bash
# Reset Question 04 - RBAC Role

kubectl delete rolebinding deploy-sa-binding -n cicd-ns --ignore-not-found
kubectl delete role deployment-manager -n cicd-ns --ignore-not-found
kubectl delete serviceaccount deploy-sa -n cicd-ns --ignore-not-found
kubectl delete namespace cicd-ns --ignore-not-found
rm -rf /opt/course/04

echo "Question 04 reset complete!"
