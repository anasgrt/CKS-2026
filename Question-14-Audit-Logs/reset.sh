#!/bin/bash
# Reset Question 14 - Audit Logs

kubectl delete secret test-secret -n audit-ns --ignore-not-found
rm -rf /opt/course/14

echo "Question 14 reset complete!"
echo "Note: API server audit configuration must be manually reverted."
