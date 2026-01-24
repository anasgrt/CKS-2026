#!/bin/bash
# Setup for Question 07 - Seccomp

set -e

echo "Creating seccomp profiles on worker nodes..."

# Create custom seccomp profile on key-worker
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null key-worker 'bash -s' << 'ENDSSH'
set -e

# Create seccomp directory
sudo mkdir -p /var/lib/kubelet/seccomp

# Create audit-log.json profile
sudo cat > /var/lib/kubelet/seccomp/audit-log.json << 'EOF'
{
  "defaultAction": "SCMP_ACT_LOG",
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_X86",
    "SCMP_ARCH_X32"
  ],
  "syscalls": [
    {
      "names": [
        "accept",
        "accept4",
        "access",
        "arch_prctl",
        "bind",
        "brk",
        "capget",
        "capset",
        "chdir",
        "chmod",
        "chown",
        "clone",
        "close",
        "connect",
        "dup",
        "dup2",
        "epoll_create",
        "epoll_ctl",
        "epoll_wait",
        "execve",
        "exit",
        "exit_group",
        "fcntl",
        "fstat",
        "futex",
        "getcwd",
        "getdents",
        "getegid",
        "geteuid",
        "getgid",
        "getpeername",
        "getpid",
        "getppid",
        "getsockname",
        "getsockopt",
        "getuid",
        "listen",
        "lseek",
        "mmap",
        "mprotect",
        "munmap",
        "nanosleep",
        "open",
        "openat",
        "read",
        "readlink",
        "recvfrom",
        "recvmsg",
        "rt_sigaction",
        "rt_sigprocmask",
        "rt_sigreturn",
        "sendmsg",
        "sendto",
        "set_robust_list",
        "set_tid_address",
        "setgid",
        "setgroups",
        "setsockopt",
        "setuid",
        "sigaltstack",
        "socket",
        "stat",
        "tgkill",
        "uname",
        "wait4",
        "write"
      ],
      "action": "SCMP_ACT_LOG"
    }
  ]
}
EOF

echo "✓ Seccomp profile 'audit-log.json' created on key-worker"
ENDSSH

# Create namespace
kubectl create namespace seccomp-ns --dry-run=client -o yaml | kubectl apply -f -

# Create output directory
mkdir -p /opt/course/07

echo ""
echo "✓ Environment ready!"
echo "  Namespace: seccomp-ns"
echo "  Seccomp profile 'audit-log.json' created on key-worker"
echo ""
echo "Verify with:"
echo "  ssh key-worker 'ls -la /var/lib/kubelet/seccomp/'"
