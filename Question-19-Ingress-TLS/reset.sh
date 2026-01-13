#!/bin/bash
# Reset Question 19 - Ingress TLS

kubectl delete ingress secure-ingress -n web-ns --ignore-not-found
kubectl delete secret web-tls-secret -n web-ns --ignore-not-found
kubectl delete service web-svc -n web-ns --ignore-not-found
kubectl delete deployment web-app -n web-ns --ignore-not-found
kubectl delete namespace web-ns --ignore-not-found
rm -rf /opt/course/19

echo "Question 19 reset complete!"
