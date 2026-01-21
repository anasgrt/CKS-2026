# Quick Reference: Node Operations

## Your Lab Nodes
```
cplane-01  172.16.0.2  [Control Plane]
node-01    172.16.0.3  [Worker]
node-02    172.16.0.4  [Worker]
```

## SSH Access
```bash
ssh cplane-01    # Control plane operations
ssh node-01      # Worker node operations (primary)
ssh node-02      # Worker node operations (secondary)
```

## Question Node Requirements

### Control Plane (cplane-01)
- **Q03:** kube-bench master, API server config
- **Q09:** Secrets encryption, etcd access
- **Q14:** Audit logging configuration
- **Q16:** ImagePolicyWebhook admission controller
- **Q17:** Binary verification (kubectl)

### Worker Node (node-01)
- **Q06:** AppArmor profile (`/etc/apparmor.d/`)
- **Q07:** Seccomp profiles (`/var/lib/kubelet/seccomp/`)
- **Q13:** Falco installation and rules

### Any Worker Node (node-01 or node-02)
- **Q01-Q20:** Pod scheduling (all questions)
- **Q15:** gVisor RuntimeClass (if configured)

## Common Commands by Node

### On cplane-01
```bash
# Edit API server manifest
sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml

# Check API server logs
kubectl logs -n kube-system kube-apiserver-cplane-01

# Run kube-bench for control plane
kube-bench run --targets master

# Access etcd directly
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get / --prefix --keys-only
```

### On node-01
```bash
# Load AppArmor profile
sudo apparmor_parser -q /etc/apparmor.d/k8s-deny-write
sudo aa-status | grep k8s

# Check Falco
sudo systemctl status falco
sudo journalctl -u falco -f

# Run kube-bench for worker
kube-bench run --targets node

# Check container runtime
crictl ps
crictl pods

# Verify seccomp profiles
ls -la /var/lib/kubelet/seccomp/
```

### On node-02
```bash
# Same as node-01 for worker operations
# Typically used for multi-node testing
```

## File Locations

### Control Plane (cplane-01)
```
/etc/kubernetes/manifests/           # Static pod manifests
/etc/kubernetes/pki/                 # Certificates
/etc/kubernetes/audit-policy.yaml    # Audit policy (Q14)
/etc/kubernetes/encryption-config.yaml # Encryption config (Q09)
/var/log/kubernetes/audit/           # Audit logs
```

### Worker Nodes (node-01, node-02)
```
/etc/apparmor.d/                     # AppArmor profiles
/var/lib/kubelet/seccomp/            # Seccomp profiles
/var/lib/kubelet/config.yaml         # Kubelet config
/etc/falco/                          # Falco configuration
```

## Verification Commands

```bash
# Check all nodes are ready
kubectl get nodes -o wide

# See which node a pod is on
kubectl get pod <pod-name> -n <namespace> -o wide

# Label nodes (if needed)
kubectl label node node-01 workload=apparmor
kubectl label node node-01 monitoring=falco

# Verify node resources
kubectl describe node cplane-01
kubectl describe node node-01
kubectl describe node node-02
```

## Troubleshooting

### Can't SSH to node
```bash
# Check node IP
kubectl get node <node-name> -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'

# Ping node
ping 172.16.0.2  # cplane-01
ping 172.16.0.3  # node-01
ping 172.16.0.4  # node-02
```

### Pod not scheduling
```bash
# Check node status
kubectl get nodes

# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check node taints
kubectl describe node node-01 | grep -i taint
```

### Node feature not working
```bash
# AppArmor on node-01
ssh node-01 'sudo aa-status'

# Falco on node-01
ssh node-01 'sudo systemctl status falco'

# Seccomp profiles
ssh node-01 'ls -la /var/lib/kubelet/seccomp/'
```
