#!/bin/bash
# Solution for Question 13 - Falco Rules

echo "Solution: Create custom Falco rule"
echo ""
echo "Step 1: SSH to node-01 and create the custom rule file"
echo ""

cat << 'EOF'
# SSH to the worker node
ssh node-01

# Create the custom Falco rule with macros as specified
cat > /etc/falco/rules.d/shell-detect.yaml << 'YAML'
# Macro: spawned_process (evt.dir is deprecated - don't use it)
- macro: spawned_process
  condition: evt.type in (execve, execveat)

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
# Restart Falco to load new rule (Falco runs as systemd service on node-01)
sudo systemctl restart falco-modern-bpf

# Verify Falco is running
sudo systemctl status falco-modern-bpf
EOF

echo ""
echo "Step 3: Trigger the rule and capture alert"
echo ""

cat << 'EOF'
# In another terminal, spawn a shell in any running pod
kubectl exec -it <any-running-pod> -- /bin/sh

# Watch Falco logs for the alert
journalctl -u falco-modern-bpf -f | grep "Shell spawned"

# Save the alert output
journalctl -u falco-modern-bpf | grep "Shell spawned" > /opt/course/13/falco-alert.txt
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
echo "- spawned_process uses evt.type in (execve, execveat)"
echo "- Note: evt.dir is DEPRECATED in modern Falco - do not use it"
echo "- container macro filters to only container events"
echo "- Output fields use Falco field syntax like %user.name, %k8s.pod.name"
echo "- Priority levels: DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL, ALERT, EMERGENCY"
echo "- Falco runs as systemd service (falco-modern-bpf) on node-01"
echo "- Use journalctl -u falco-modern-bpf to view logs"
