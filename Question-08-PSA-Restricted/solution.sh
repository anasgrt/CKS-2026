#!/bin/bash
# Solution for Question 08 - PSA Restricted

echo "Solution: Configure Pod Security Admission"
echo ""
echo "Step 1: Create namespace with PSA labels"
echo ""

cat << 'EOF'
cat > /opt/course/08/namespace.yaml << 'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: psa-restricted
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
YAML

kubectl apply -f /opt/course/08/namespace.yaml
EOF

echo ""
echo "Quick alternative using kubectl:"
echo "kubectl label namespace psa-restricted \\"
echo "  pod-security.kubernetes.io/enforce=restricted \\"
echo "  pod-security.kubernetes.io/warn=restricted \\"
echo "  pod-security.kubernetes.io/audit=restricted"
echo ""

echo "Step 2: Create secure pod"
echo ""

cat << 'EOF'
cat > /opt/course/08/pod.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: psa-restricted
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      capabilities:
        drop:
          - ALL
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

kubectl apply -f /opt/course/08/pod.yaml
EOF

echo ""
echo "Step 3: Test non-compliant pod rejection"
echo ""

cat << 'EOF'
# Try to create a non-compliant pod (running as root, privileged)
# This WILL be rejected and we capture the error

kubectl run bad-pod --image=nginx --privileged -n psa-restricted 2>&1 | tee /opt/course/08/rejected-error.txt

# Or with a pod manifest:
cat > /tmp/bad-pod.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: bad-pod
  namespace: psa-restricted
spec:
  containers:
  - name: bad
    image: nginx
    securityContext:
      privileged: true
      runAsUser: 0
YAML

kubectl apply -f /tmp/bad-pod.yaml 2>&1 | tee /opt/course/08/rejected-error.txt

# The error should contain messages like:
# - "violates PodSecurity"
# - "restricted:latest"
# - "allowPrivilegeEscalation != false" or "privileged"
EOF

echo ""
echo "Step 4: Verify the pod is running"
echo ""
echo "kubectl get pods -n psa-restricted"
echo ""
echo "Key Points:"
echo "- PSA replaces deprecated PodSecurityPolicy"
echo "- Labels are applied at namespace level"
echo "- 'restricted' profile requires non-root, dropped caps, no privilege escalation"
echo "- Use emptyDir volumes for nginx since root filesystem is read-only"
echo "- Always include seccompProfile: RuntimeDefault for restricted compliance"
echo "- Non-compliant pods are REJECTED at admission time (not just warned)"
