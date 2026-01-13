#!/bin/bash
# Reset Question 06 - AppArmor

kubectl delete pod secured-pod -n apparmor-ns --ignore-not-found
rm -rf /opt/course/06

echo "Question 06 reset complete!"
