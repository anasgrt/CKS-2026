#!/bin/bash
# Solution for Question 10 - SecurityContext

echo "Solution: Create hardened pod with SecurityContext"
echo ""

cat << 'EOF'
cat > /opt/course/10/pod.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: hardened-pod
  namespace: hardened-ns
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    runAsNonRoot: true
  containers:
  - name: nginx
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
        add:
          - NET_BIND_SERVICE
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: cache
      mountPath: /var/cache/nginx
    - name: run
      mountPath: /var/run
  volumes:
  - name: tmp
    emptyDir: {}
  - name: cache
    emptyDir: {}
  - name: run
    emptyDir: {}
YAML

kubectl apply -f /opt/course/10/pod.yaml
EOF

echo ""
echo "Key Points:"
echo ""
echo "Pod-level securityContext:"
echo "  - runAsUser/runAsGroup: Sets UID/GID for all containers"
echo "  - fsGroup: Group ID applied to mounted volumes"
echo "  - runAsNonRoot: Validates container doesn't run as root"
echo ""
echo "Container-level securityContext:"
echo "  - allowPrivilegeEscalation: Prevents gaining more privileges"
echo "  - readOnlyRootFilesystem: Prevents writing to container filesystem"
echo "  - capabilities: Fine-grained Linux capability control"
echo ""
echo "Common capabilities:"
echo "  - NET_BIND_SERVICE: Bind to ports < 1024"
echo "  - SYS_TIME: Modify system clock"
echo "  - NET_ADMIN: Network administration"
