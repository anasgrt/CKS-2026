#!/bin/bash
# Reset Question 13 - Falco Rules

# Delete test pod
kubectl delete pod test-pod -n falco-ns --ignore-not-found 2>/dev/null

# Clean up custom Falco rules on key-worker
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR key-worker 'bash -s' << 'ENDSSH' 2>/dev/null || true
# Remove custom rules created by user
sudo rm -f /etc/falco/rules.d/*.yaml 2>/dev/null
# Restart Falco to pick up changes
sudo systemctl restart falco-modern-bpf.service 2>/dev/null || sudo systemctl restart falco 2>/dev/null || true
ENDSSH

# Clean up output directory
rm -rf /opt/course/13

echo "Question 13 reset complete!"
