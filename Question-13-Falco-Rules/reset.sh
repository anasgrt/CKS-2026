#!/bin/bash
# Reset Question 13 - Falco Rules

kubectl delete pod test-pod -n falco-ns --ignore-not-found
rm -rf /opt/course/13

echo "Question 13 reset complete!"
echo "Note: Custom Falco rules in /etc/falco/rules.d/ must be manually removed."
