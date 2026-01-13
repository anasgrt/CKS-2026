# CKS Exam Simulator 2026

A killer.sh-style practice environment for the **Certified Kubernetes Security Specialist (CKS)** exam, updated for the **October 2024 curriculum changes** and Kubernetes v1.34.

> ⚠️ **CKS 2026 Updates**: This simulator has been refactored based on extensive research from real exam feedback, Reddit discussions, and community experiences to closely mirror the actual CKS exam format and difficulty.

## 🎯 Overview

This simulator contains **20 practice questions** covering all 6 CKS exam domains with realistic exam-style scenarios:

| Domain | Weight | Questions |
|--------|--------|-----------|
| Cluster Setup | 15% | Q1, Q2, Q3, Q17, Q19 |
| Cluster Hardening | 15% | Q4, Q5, Q18, Q20 |
| System Hardening | 10% | Q6, Q7, Q15 |
| Minimize Microservice Vulnerabilities | 20% | Q8, Q9, Q10 |
| Supply Chain Security | 20% | Q11, Q12, Q16 |
| Monitoring, Logging & Runtime Security | 20% | Q13, Q14 |

### 🆕 October 2024 Curriculum Changes
- **Cilium Network Encryption** added (pod-to-pod encryption with IPSec/WireGuard)
- **Enhanced Falco** focus with macros, lists, and Kubernetes metadata
- **Pod Security Admission (PSA)** fully replaces deprecated PodSecurityPolicy
- **Audit Logging** expanded with volumeMount configurations and all log levels

## 🚀 Getting Started

### Prerequisites
- A Kubernetes cluster (kind, minikube, or real cluster) - Kubernetes v1.30+
- `kubectl` configured and working
- Root/sudo access for some questions
- Tools: `trivy`, `kubesec`, `falco`, `kube-bench`, `cilium` CLI (for specific questions)
- `etcdctl` for encryption verification (Q09)
- `crictl` for container runtime inspection (Q13)

### Quick Start

```bash
# Make scripts executable
chmod +x scripts/run-question.sh
find . -name '*.sh' -exec chmod +x {} \;

# List all questions
./scripts/run-question.sh list

# Setup a specific question
./scripts/run-question.sh setup 1

# Work on the question...

# Verify your solution
./scripts/run-question.sh verify 1

# Need help? Show the solution
./scripts/run-question.sh solution 1

# Reset and try again
./scripts/run-question.sh reset 1
```

## 📋 Commands

| Command | Description |
|---------|-------------|
| `list` | List all available questions |
| `setup <N>` | Setup environment for question N |
| `verify <N>` | Verify your solution |
| `solution <N>` | Display the solution |
| `reset <N>` | Reset the environment |
| `question <N>` | Display question text |
| `exam` | Start full exam simulation |

## 📚 Question Topics

### Domain 1: Cluster Setup (15%)
- **Q01**: NetworkPolicy - Default Deny All (microservices isolation)
- **Q02**: NetworkPolicy - Allow Specific Traffic (multi-tier apps)
- **Q03**: CIS Benchmarks & kube-bench (master, worker, etcd scanning)
- **Q17**: Binary Verification (sha512sum)
- **Q19**: Ingress TLS Configuration (self-signed certificates)

### Domain 2: Cluster Hardening (15%)
- **Q04**: RBAC Role & RoleBinding (CI/CD service accounts)
- **Q05**: ServiceAccount Security (token projection, automount)
- **Q18**: Node Metadata Protection (blocking 169.254.169.254)
- **Q20**: RBAC ClusterRole & ClusterRoleBinding (read-only monitoring)

### Domain 3: System Hardening (10%)
- **Q06**: AppArmor Profiles (K8s 1.30+ syntax)
- **Q07**: Seccomp Profiles (RuntimeDefault + Localhost)
- **Q15**: Cilium Pod-to-Pod Encryption (IPSec/WireGuard) ⭐ NEW

### Domain 4: Minimize Microservice Vulnerabilities (20%)
- **Q08**: Pod Security Admission (PSA) - Restricted mode
- **Q09**: Secrets Encryption at Rest (aescbc, etcdctl verification)
- **Q10**: SecurityContext Hardening (runAsNonRoot, readOnlyRootFilesystem)

### Domain 5: Supply Chain Security (20%)
- **Q11**: Trivy Image Scanning (multi-image comparison)
- **Q12**: Kubesec Analysis (score improvement workflow)
- **Q16**: ImagePolicyWebhook (admission controller configuration)

### Domain 6: Monitoring, Logging & Runtime Security (20%)
- **Q13**: Falco Rules (macros, crictl, Kubernetes metadata) ⭐ HIGH WEIGHT
- **Q14**: Kubernetes Audit Logs (full policy with omitStages, volumeMounts)

## 💡 Tips for the CKS Exam 2026

### ⏱️ Time Management
1. **Budget wisely**: 2 hours for ~15-20 questions. Average ~6 mins per question.
2. **Prioritize by weight**: Falco, Supply Chain, and Microservice Vulnerabilities are 60% combined!
3. **Flag and move on**: Don't get stuck - mark difficult questions and return later.

### 🔧 Technical Tips
1. **Use kubectl shortcuts**: `alias k=kubectl`, enable bash completion
2. **Know the docs**: Bookmark key pages in kubernetes.io/docs
3. **Practice imperative commands**: Faster than writing YAML
4. **Read questions carefully**: Namespace, resource names, exact requirements

### 🔥 High-Priority Topics for CKS 2026
1. **Falco (20% domain)**: Learn rule structure (Rule, Desc, Condition, Output, Priority), macros, and `crictl` for container investigation
2. **NetworkPolicies**: Both ingress AND egress, pod selectors, namespace selectors
3. **Audit Logging**: Master volumeMounts (File vs DirectoryOrCreate), all 4 log levels
4. **PSA**: Restricted mode enforcement, label syntax, exception handling
5. **Cilium Encryption**: New topic - understand IPSec vs WireGuard basics

### 🛠️ Essential Commands to Master
```bash
# Falco investigation
crictl ps | grep <container>
crictl inspect <container-id>
journalctl -u falco

# Audit log verification
cat /var/log/kubernetes/audit/audit.log | jq '.items[-5:]'

# Cilium status
cilium encrypt status
cilium status

# PSA namespace labels
kubectl label ns <namespace> pod-security.kubernetes.io/enforce=restricted
```

## 🔧 Useful Commands

```bash
# Quick YAML generation
kubectl run pod --image=nginx --dry-run=client -o yaml
kubectl create deploy --dry-run=client -o yaml
kubectl create role/rolebinding --dry-run=client -o yaml

# Debug NetworkPolicy
kubectl exec -it <pod> -- curl <target-ip>:<port>
kubectl exec -it <pod> -- wget -qO- --timeout=2 <service>.<namespace>

# Check RBAC
kubectl auth can-i <verb> <resource> --as=<user>
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa>

# View logs
kubectl logs <pod> -c <container>
journalctl -u kubelet
journalctl -u falco

# Secrets/Encryption verification
ETCDCTL_API=3 etcdctl get /registry/secrets/<ns>/<secret> --endpoints=... --cacert=... --cert=... --key=...

# AppArmor (K8s 1.30+)
aa-status | grep <profile>

# kube-bench
kube-bench run --targets master,node,etcd
```

## 📁 Directory Structure

```
CKS-2026/
├── scripts/
│   └── run-question.sh       # Main runner script
├── Question-01-NetworkPolicy-DenyAll/
│   ├── question.txt          # Question description
│   ├── setup.sh             # Environment setup
│   ├── verify.sh            # Solution verification
│   ├── solution.sh          # Step-by-step solution
│   └── reset.sh             # Cleanup
├── Question-02-.../
│   └── ...
├── Question-15-RuntimeClass-Sandbox/  # (Contains Cilium Encryption question)
│   └── ...
└── README.md
```

> **Note**: Q15 folder is named `RuntimeClass-Sandbox` but contains Cilium Pod-to-Pod Encryption content (CKS 2026 curriculum update).

## 🎓 Exam Registration

- **CKS Exam**: [Linux Foundation Training](https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/)
- **Duration**: 2 hours
- **Format**: Performance-based (hands-on)
- **Passing Score**: 67%
- **Prerequisites**: Valid CKA certification

## 📖 Additional Resources

- [Kubernetes Security Documentation](https://kubernetes.io/docs/concepts/security/)
- [CKS Curriculum](https://github.com/cncf/curriculum)
- [Killer.sh CKS Simulator](https://killer.sh/cks)
- [Kubernetes Hardening Guide (NSA/CISA)](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)

---

**Good luck with your CKS exam preparation! 🚀**
