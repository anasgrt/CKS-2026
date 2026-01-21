# Node Name Mapping - Lab Configuration

This document details the node name mappings used in this CKS practice environment to match your specific lab setup.

## Your Lab Nodes

```
NAME        STATUS   ROLES           VERSION   INTERNAL-IP
cplane-01   Ready    control-plane   v1.35.0   172.16.0.2
node-01     Ready    <none>          v1.35.0   172.16.0.3
node-02     Ready    <none>          v1.35.0   172.16.0.4
```

## Node Mapping Applied

The following node name references have been updated throughout the codebase:

| Original Name   | Updated To | Role          | Usage                                    |
|----------------|------------|---------------|------------------------------------------|
| controlplane   | cplane-01  | Control Plane | API server, etcd, kube-bench master      |
| worker-node-1  | node-01    | Worker Node   | AppArmor, Falco, workload scheduling     |
| worker-node-2  | node-02    | Worker Node   | Additional worker for multi-node tasks   |

## Files Updated

### Question 03 - CIS Benchmark
- **question.txt**: Updated control plane reference from `controlplane` to `cplane-01`
- **question.txt**: Updated worker node reference from `worker-node-1` to `node-01`
- SSH instructions updated: `ssh cplane-01` and `ssh node-01`

### Question 06 - AppArmor
- **question.txt**: Updated worker node reference from `worker-node-1` to `node-01`
- **solution.sh**: Updated SSH command to `ssh node-01`
- AppArmor profile verification instructions updated

### Question 13 - Falco Rules
- **question.txt**: Updated Falco installation node from `worker-node-1` to `node-01`
- **solution.sh**: Updated SSH command to `ssh node-01`

## Important Notes

### Control Plane Operations
When questions require control plane access (API server config, kube-bench master, etcd):
```bash
ssh cplane-01
```

### Worker Node Operations
When questions require worker node access (AppArmor, Seccomp profiles, Falco, crictl):
```bash
ssh node-01   # Primary worker
ssh node-02   # Secondary worker (if needed)
```

### Node-Specific Features
Certain features need to be installed on specific nodes:

| Feature          | Node      | Questions |
|------------------|-----------|-----------|
| AppArmor Profile | node-01   | Q06       |
| Seccomp Profile  | All nodes | Q07       |
| Falco            | node-01   | Q13       |
| gVisor Runtime   | All nodes | Q15       |
| kube-bench       | All nodes | Q03       |

### kube-bench Commands
The `kube-bench` tool uses standard target names regardless of node names:
```bash
# On control plane (cplane-01)
kube-bench run --targets master

# On worker nodes (node-01, node-02)
kube-bench run --targets node
```

## Verification

After setup, verify your nodes match the expected configuration:

```bash
# Check node names and status
kubectl get nodes -o wide

# Verify control plane node
kubectl get nodes cplane-01

# Verify worker nodes
kubectl get nodes node-01 node-02
```

## Lab Consistency

All questions maintain the same logic and security concepts while using your lab's node names:
- Network policies work the same regardless of node names
- RBAC and security contexts are node-agnostic
- Pod scheduling works across all worker nodes (node-01, node-02)
- Control plane configuration always happens on cplane-01

## Quick Reference

**Control Plane Node:** `cplane-01` (172.16.0.2)
- API Server: /etc/kubernetes/manifests/kube-apiserver.yaml
- etcd: /etc/kubernetes/manifests/etcd.yaml
- Audit logs: /var/log/kubernetes/audit/
- Certificate directory: /etc/kubernetes/pki/

**Worker Nodes:** `node-01`, `node-02` (172.16.0.3, 172.16.0.4)
- Kubelet config: /var/lib/kubelet/config.yaml
- AppArmor profiles: /etc/apparmor.d/
- Seccomp profiles: /var/lib/kubelet/seccomp/
- Container runtime: containerd (crictl commands)

---

**Note**: The codebase maintains the exact same security logic, question structure, and learning objectives. Only node name references have been updated to match your lab environment.
