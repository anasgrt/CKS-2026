#!/bin/bash
# Reset Question 12 - Kubesec Analysis

kubectl delete deployment web-app -n kubesec-ns --ignore-not-found
rm -rf /opt/course/12

echo "Question 12 reset complete!"
