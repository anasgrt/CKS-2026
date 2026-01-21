#!/bin/bash
# Solution for Question 13 - Falco Rules

echo "Solution: Create custom Falco rule"
echo ""
echo "Step 1: SSH to node-01 and create the custom rule file"
echo ""

cat << 'EOF'
# SSH to the worker node
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null node-01

# Create the custom Falco rule with macros as specified
cat > /etc/falco/rules.d/shell-detect.yaml << 'YAML'
# Macro: spawned_process
- macro: spawned_process
  condition: evt.type = execve and evt.dir = <

# Macro: container
- macro: container
  condition: container.id != host

# Rule: Shell Spawned in Container
- rule: Shell Spawned in Container
  desc: Detect when a shell is spawned inside a container
  condition: >
    spawned_process and container and proc.name in (bash, sh, ash, dash, zsh)
  output: >
    Shell spawned in container (user=%user.name command=%proc.cmdline
    container=%container.name pod=%k8s.pod.name namespace=%k8s.ns.name)
  priority: WARNING
  tags: [container, shell, mitre_execution]
YAML
EOF

echo ""
echo "Step 2: Restart Falco service"
echo ""

cat << 'EOF'
# Restart Falco to load new rule
sudo systemctl restart falco

# Verify Falco is running
sudo systemctl status falco

# OR if Falco is running as DaemonSet
kubectl delete pod -n falco -l app=falco
EOF

echo ""
echo "Step 3: Trigger the rule and capture alert"
echo ""

cat << 'EOF'
# In another terminal, spawn a shell in any running pod
kubectl exec -it <any-running-pod> -- /bin/sh

# Watch Falco logs for the alert
journalctl -u falco -f | grep "Shell Spawned"

# Save the alert output
journalctl -u falco | grep "Shell Spawned" > /opt/course/13/falco-alert.txt
EOF

echo ""
echo "Step 4: Find container ID using crictl"
echo ""

cat << 'EOF'
# List recent containers
crictl ps

# Find the container where shell was spawned (look at CREATED column)
crictl ps | grep <pod-name>

# Save the container ID
echo "<container-id>" > /opt/course/13/container-id.txt
EOF

echo ""
echo "Key Points:"
echo "- Falco macros allow reusable conditions"
echo "- spawned_process uses evt.type=execve and evt.dir=< (entering syscall)"
echo "- container macro filters to only container events"
echo "- Output fields use Falco field syntax like %user.name, %k8s.pod.name"
echo "- Priority levels: DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL, ALERT, EMERGENCY"
echo "- Use journalctl for systemd-managed Falco, kubectl logs for DaemonSet"
