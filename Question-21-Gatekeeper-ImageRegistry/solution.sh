#!/bin/bash
# Solution for Question 21 - Gatekeeper Image Registry Restriction
# Based on real CKS exam patterns (2025/2026)

echo "=============================================="
echo "Solution: Gatekeeper Image Registry Restriction"
echo "=============================================="
echo ""

echo "STEP 1: Verify Gatekeeper is installed"
echo "--------------------------------------"
echo ""
cat << 'EOF'
kubectl get pods -n gatekeeper-system
# Should see gatekeeper-controller-manager and gatekeeper-audit pods
EOF

echo ""
echo "STEP 2: Create the ConstraintTemplate"
echo "-------------------------------------"
echo ""

cat << 'EOF'
# /opt/course/21/constraint-template.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sallowedrepos
spec:
  crd:
    spec:
      names:
        kind: K8sAllowedRepos
      validation:
        openAPIV3Schema:
          type: object
          properties:
            repos:
              type: array
              items:
                type: string
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8sallowedrepos

      violation[{"msg": msg}] {
        container := input.review.object.spec.containers[_]
        satisfied := [good | repo = input.parameters.repos[_]; good = startswith(container.image, repo)]
        not any(satisfied)
        msg := sprintf("Container '%v' uses image '%v' which is not from an allowed registry. Allowed: %v", [container.name, container.image, input.parameters.repos])
      }

      # Also check init containers
      violation[{"msg": msg}] {
        container := input.review.object.spec.initContainers[_]
        satisfied := [good | repo = input.parameters.repos[_]; good = startswith(container.image, repo)]
        not any(satisfied)
        msg := sprintf("Init container '%v' uses image '%v' which is not from an allowed registry. Allowed: %v", [container.name, container.image, input.parameters.repos])
      }
EOF

echo ""
echo "Command to create the file:"
echo ""

cat << 'HEREDOC'
cat > /opt/course/21/constraint-template.yaml << 'TEMPLATE'
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sallowedrepos
spec:
  crd:
    spec:
      names:
        kind: K8sAllowedRepos
      validation:
        openAPIV3Schema:
          type: object
          properties:
            repos:
              type: array
              items:
                type: string
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8sallowedrepos

      violation[{"msg": msg}] {
        container := input.review.object.spec.containers[_]
        satisfied := [good | repo = input.parameters.repos[_]; good = startswith(container.image, repo)]
        not any(satisfied)
        msg := sprintf("Container '%v' uses image '%v' which is not from an allowed registry. Allowed: %v", [container.name, container.image, input.parameters.repos])
      }

      violation[{"msg": msg}] {
        container := input.review.object.spec.initContainers[_]
        satisfied := [good | repo = input.parameters.repos[_]; good = startswith(container.image, repo)]
        not any(satisfied)
        msg := sprintf("Init container '%v' uses image '%v' which is not from an allowed registry. Allowed: %v", [container.name, container.image, input.parameters.repos])
      }
TEMPLATE

kubectl apply -f /opt/course/21/constraint-template.yaml
HEREDOC

echo ""
echo "STEP 3: Create the Constraint"
echo "-----------------------------"
echo ""

cat << 'EOF'
# /opt/course/21/constraint.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: allowed-repos
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
    namespaces:
    - "gatekeeper-test"
    - "default"
  parameters:
    repos:
    - "docker.io/library/"
    - "gcr.io/google-containers/"
    - "registry.k8s.io/"
EOF

echo ""
echo "Command to create the file:"
echo ""

cat << 'HEREDOC'
cat > /opt/course/21/constraint.yaml << 'CONSTRAINT'
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: allowed-repos
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
    namespaces:
    - "gatekeeper-test"
    - "default"
  parameters:
    repos:
    - "docker.io/library/"
    - "gcr.io/google-containers/"
    - "registry.k8s.io/"
CONSTRAINT

kubectl apply -f /opt/course/21/constraint.yaml
HEREDOC

echo ""
echo "STEP 4: Wait for constraint to be ready"
echo "---------------------------------------"
echo ""

cat << 'EOF'
# IMPORTANT: Wait for Gatekeeper to sync the constraint
# This typically takes 5-10 seconds
sleep 10

# Verify constraint is enforced and has no violations yet
kubectl get k8sallowedrepos
kubectl describe k8sallowedrepos allowed-repos | grep -A5 "Status:"
EOF

echo ""
echo "STEP 5: Test with allowed image"
echo "-------------------------------"
echo ""

cat << 'EOF'
# This should SUCCEED (docker.io/library/ is allowed)
kubectl run allowed-nginx --image=docker.io/library/nginx:alpine -n gatekeeper-test
# OR simply (nginx resolves to docker.io/library/nginx)
kubectl run allowed-nginx --image=nginx:alpine -n gatekeeper-test

# Verify pod is created
kubectl get pod allowed-nginx -n gatekeeper-test
EOF

echo ""
echo "STEP 6: Test with disallowed image"
echo "----------------------------------"
echo ""

cat << 'EOF'
# This should FAIL (quay.io is not in allowed list)
kubectl run disallowed-app --image=quay.io/some-org/some-image:v1 -n gatekeeper-test 2>&1 | tee /opt/course/21/rejected-error.txt

# Or try with another unauthorized registry
kubectl run disallowed-app --image=unauthorized-registry.com/app:v1 -n gatekeeper-test 2>&1 | tee /opt/course/21/rejected-error.txt
EOF

echo ""
echo "=============================================="
echo "KEY POINTS TO REMEMBER"
echo "=============================================="
echo ""
echo "1. ConstraintTemplate defines the POLICY LOGIC (Rego)"
echo "2. Constraint APPLIES the policy with specific parameters"
echo "3. Apply ConstraintTemplate FIRST, then Constraint"
echo "4. Include trailing slash in registry prefixes (docker.io/library/)"
echo "5. Check both containers AND initContainers"
echo "6. Wait a few seconds after applying constraint before testing"
echo ""
echo "COMMON TRAP: Images like 'nginx:alpine' resolve to 'docker.io/library/nginx:alpine'"
echo "so you need to include 'docker.io/library/' in allowed repos"
