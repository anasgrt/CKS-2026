#!/bin/bash
# Reset Question 02 - NetworkPolicy Allow Specific Traffic

set -e

kubectl delete networkpolicy api-policy database-policy -n microservices-ns --ignore-not-found
kubectl delete pod frontend api database -n microservices-ns --ignore-not-found
kubectl delete namespace microservices-ns monitoring-ns --ignore-not-found
rm -rf /opt/course/02

echo "Question 02 reset complete!"
