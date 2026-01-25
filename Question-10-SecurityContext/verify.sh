#!/bin/bash
# Verify Question 10 - SecurityContext

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASS=true

echo "Checking SecurityContext configuration..."
echo ""

# Check namespace exists
if kubectl get namespace hardened-ns &>/dev/null; then
    echo -e "${GREEN}✓ Namespace 'hardened-ns' exists${NC}"
else
    echo -e "${RED}✗ Namespace 'hardened-ns' not found${NC}"
    PASS=false
fi

if kubectl get pod hardened-pod -n hardened-ns &>/dev/null; then
    echo -e "${GREEN}✓ Pod 'hardened-pod' exists${NC}"

    # Check image (question requires nginx:alpine)
    IMAGE=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.containers[0].image}')
    if [[ "$IMAGE" == *"nginx"* ]] && [[ "$IMAGE" == *"alpine"* ]]; then
        echo -e "${GREEN}✓ Uses nginx:alpine image${NC}"
    else
        echo -e "${RED}✗ Should use nginx:alpine image (as per question)${NC}"
        PASS=false
    fi

    # Check runAsUser (must be non-root, i.e., not 0)
    RUN_AS_USER=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.securityContext.runAsUser}')
    if [ -n "$RUN_AS_USER" ] && [ "$RUN_AS_USER" != "0" ]; then
        echo -e "${GREEN}✓ runAsUser: $RUN_AS_USER (non-root)${NC}"
    else
        echo -e "${RED}✗ runAsUser should be set to a non-root value (not 0)${NC}"
        PASS=false
    fi

    # Check runAsGroup (should be set, any non-zero value is acceptable)
    RUN_AS_GROUP=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.securityContext.runAsGroup}')
    if [ -n "$RUN_AS_GROUP" ] && [ "$RUN_AS_GROUP" != "0" ]; then
        echo -e "${GREEN}✓ runAsGroup: $RUN_AS_GROUP (non-root)${NC}"
    else
        echo -e "${RED}✗ runAsGroup should be set to a non-root value (not 0)${NC}"
        PASS=false
    fi

    # Check fsGroup (should be set for volume permissions)
    FS_GROUP=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.securityContext.fsGroup}')
    if [ -n "$FS_GROUP" ]; then
        echo -e "${GREEN}✓ fsGroup: $FS_GROUP${NC}"
    else
        echo -e "${RED}✗ fsGroup should be set for volume permissions${NC}"
        PASS=false
    fi

    # Check runAsNonRoot
    RUN_AS_NON_ROOT=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.securityContext.runAsNonRoot}')
    if [ "$RUN_AS_NON_ROOT" == "true" ]; then
        echo -e "${GREEN}✓ runAsNonRoot: true${NC}"
    else
        echo -e "${RED}✗ runAsNonRoot should be true${NC}"
        PASS=false
    fi

    # Check seccompProfile
    SECCOMP_TYPE=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.securityContext.seccompProfile.type}')
    if [ "$SECCOMP_TYPE" == "RuntimeDefault" ]; then
        echo -e "${GREEN}✓ seccompProfile: RuntimeDefault${NC}"
    else
        echo -e "${RED}✗ seccompProfile type should be RuntimeDefault${NC}"
        PASS=false
    fi

    # Check allowPrivilegeEscalation
    ALLOW_PRIV=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation}')
    if [ "$ALLOW_PRIV" == "false" ]; then
        echo -e "${GREEN}✓ allowPrivilegeEscalation: false${NC}"
    else
        echo -e "${RED}✗ allowPrivilegeEscalation should be false${NC}"
        PASS=false
    fi

    # Check readOnlyRootFilesystem
    READ_ONLY=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.containers[0].securityContext.readOnlyRootFilesystem}')
    if [ "$READ_ONLY" == "true" ]; then
        echo -e "${GREEN}✓ readOnlyRootFilesystem: true${NC}"
    else
        echo -e "${RED}✗ readOnlyRootFilesystem should be true${NC}"
        PASS=false
    fi

    # Check capabilities drop ALL
    DROP_CAPS=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop}')
    if [[ "$DROP_CAPS" == *"ALL"* ]]; then
        echo -e "${GREEN}✓ Capabilities: drop ALL${NC}"
    else
        echo -e "${RED}✗ Should drop ALL capabilities${NC}"
        PASS=false
    fi

    # Check capabilities add NET_BIND_SERVICE (optional)
    ADD_CAPS=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.containers[0].securityContext.capabilities.add}')
    if [[ "$ADD_CAPS" == *"NET_BIND_SERVICE"* ]]; then
        echo -e "${GREEN}✓ Capabilities: add NET_BIND_SERVICE${NC}"
    fi

    # Check volume mounts for emptyDir
    MOUNT_TMP=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.containers[0].volumeMounts[?(@.mountPath=="/tmp")].name}')
    MOUNT_CACHE=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.containers[0].volumeMounts[?(@.mountPath=="/var/cache/nginx")].name}')
    MOUNT_RUN=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.containers[0].volumeMounts[?(@.mountPath=="/var/run")].name}')

    if [ -n "$MOUNT_TMP" ]; then
        echo -e "${GREEN}✓ Volume mounted at /tmp${NC}"
    else
        echo -e "${RED}✗ Should have volume mounted at /tmp${NC}"
        PASS=false
    fi

    if [ -n "$MOUNT_CACHE" ]; then
        echo -e "${GREEN}✓ Volume mounted at /var/cache/nginx${NC}"
    else
        echo -e "${RED}✗ Should have volume mounted at /var/cache/nginx${NC}"
        PASS=false
    fi

    if [ -n "$MOUNT_RUN" ]; then
        echo -e "${GREEN}✓ Volume mounted at /var/run${NC}"
    else
        echo -e "${RED}✗ Should have volume mounted at /var/run${NC}"
        PASS=false
    fi

    # Check no host namespaces
    HOST_NET=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.hostNetwork}')
    HOST_PID=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.hostPID}')
    HOST_IPC=$(kubectl get pod hardened-pod -n hardened-ns -o jsonpath='{.spec.hostIPC}')

    if [ "$HOST_NET" != "true" ] && [ "$HOST_PID" != "true" ] && [ "$HOST_IPC" != "true" ]; then
        echo -e "${GREEN}✓ No host namespaces used${NC}"
    else
        echo -e "${RED}✗ Should not use host namespaces${NC}"
        PASS=false
    fi
else
    echo -e "${RED}✗ Pod 'hardened-pod' not found${NC}"
    PASS=false
fi

# Check manifest files saved
echo ""
echo "Checking manifest files..."
if [ -f "/opt/course/10/pod.yaml" ]; then
    echo -e "${GREEN}✓ pod.yaml saved${NC}"
else
    echo -e "${RED}✗ pod.yaml not found at /opt/course/10/pod.yaml${NC}"
    PASS=false
fi

if [ -f "/opt/course/10/pod-status.txt" ]; then
    echo -e "${GREEN}✓ pod-status.txt saved${NC}"
else
    echo -e "${RED}✗ pod-status.txt not found at /opt/course/10/pod-status.txt${NC}"
    PASS=false
fi

if $PASS; then
    exit 0
else
    exit 1
fi
