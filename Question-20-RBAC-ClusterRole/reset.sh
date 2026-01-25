#!/bin/bash
# Reset Question 20 - RBAC ClusterRole

kubectl delete clusterrolebinding cluster-monitor-binding --ignore-not-found
kubectl delete clusterrole cluster-monitor --ignore-not-found
kubectl delete serviceaccount monitor-sa -n monitoring --ignore-not-found
kubectl delete namespace monitoring --ignore-not-found
# Delete test namespaces created by setup
kubectl delete namespace test-ns1 test-ns2 --ignore-not-found
rm -rf /opt/course/20

echo "Question 20 reset complete!"
