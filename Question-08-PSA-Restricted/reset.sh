#!/bin/bash
# Reset Question 08 - PSA Restricted

kubectl delete pod secure-pod -n psa-restricted --ignore-not-found
kubectl delete namespace psa-restricted --ignore-not-found
rm -rf /opt/course/08

echo "Question 08 reset complete!"
