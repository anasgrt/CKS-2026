#!/bin/bash
# Solution for Question 12 - Kubesec Analysis

echo "Solution: Analyze and fix deployment with Kubesec"
echo ""
echo "Step 1: Run Kubesec scan"
echo ""

cat << 'EOF'
kubesec scan /opt/course/12/insecure-deploy.yaml > /opt/course/12/kubesec-report.json

# OR with Docker:
docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin < /opt/course/12/insecure-deploy.yaml > /opt/course/12/kubesec-report.json
EOF

echo ""
echo "Step 2: Review the report (shows score and suggestions)"
echo ""
echo "cat /opt/course/12/kubesec-report.json | jq"
echo ""
echo "Step 3: Create fixed deployment"
echo ""

cat << 'EOF'
cat > /opt/course/12/secure-deploy.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: kubesec-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
      containers:
      - name: web
        image: nginx
        ports:
        - containerPort: 80
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
              - ALL
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
          requests:
            memory: "64Mi"
            cpu: "250m"
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
EOF

echo ""
echo "Step 4: Apply the fixed deployment"
echo ""
echo "kubectl apply -f /opt/course/12/secure-deploy.yaml"
echo ""
echo "Kubesec scoring (examples):"
echo "  +1: runAsNonRoot: true"
echo "  +1: runAsUser > 10000"  
echo "  +1: readOnlyRootFilesystem: true"
echo "  +1: capabilities drop ALL"
echo "  +1: resource limits set"
echo "  -30: privileged: true"
echo "  -9: CAP_SYS_ADMIN capability"
