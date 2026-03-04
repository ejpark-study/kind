#!/usr/bin/env bash

POD_SUBNET=10.10.0.0/16
SVC_SUBNET=10.11.0.0/16
echo "POD_SUBNET: ${POD_SUBNET}, SVC_SUBNET: ${SVC_SUBNET}"

VOLUME_PATH=$(pwd)/volume
echo "VOLUME_PATH: ${VOLUME_PATH}"

HOST_IP=$(python3 -c 'import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.connect(("8.8.8.8", 80)); print(s.getsockname()[0]); s.close()')
echo "HOST_IP: ${HOST_IP}"

NODE_VERSION=v1.35.0
echo "NODE_VERSION: ${NODE_VERSION}"

cat <<EOF > kind-calico.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

kubeadmConfigPatches:
- |
  apiVersion: kubelet.config.k8s.io/v1beta1
  kind: KubeletConfiguration
  evictionHard:
    nodefs.available: "0%"

kubeadmConfigPatchesJSON6902:
- group: kubeadm.k8s.io
  version: v1beta3
  kind: ClusterConfiguration
  patch: |
    - op: add
      path: /apiServer/certSANs/-
      value: kind

networking:
  disableDefaultCNI: true
  kubeProxyMode: "iptables" 
  podSubnet: "${POD_SUBNET}"
  serviceSubnet: "${SVC_SUBNET}"

nodes:
- role: control-plane
  labels:
    name: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    listenAddress: "0.0.0.0"
  - containerPort: 443
    hostPort: 443
    listenAddress: "0.0.0.0"
  kubeadmConfigPatches:
  - |
    apiVersion: kubelet.config.k8s.io/v1beta1
    kind: KubeletConfiguration
    evictionHard:
      nodefs.available: "0%"
  extraMounts:
  - hostPath: ${VOLUME_PATH}/shared
    containerPath: /shared
- role: worker
  extraMounts:
  - hostPath: ${VOLUME_PATH}/shared
    containerPath: /shared
  - hostPath: ${VOLUME_PATH}/worker1/data
    containerPath: /var/local-path-provisioner
- role: worker
  extraMounts:
  - hostPath: ${VOLUME_PATH}/shared
    containerPath: /shared
  - hostPath: ${VOLUME_PATH}/worker2/data
    containerPath: /var/local-path-provisioner
- role: worker
  extraMounts:
  - hostPath: ${VOLUME_PATH}/shared
    containerPath: /shared
  - hostPath: ${VOLUME_PATH}/worker3/data
    containerPath: /var/local-path-provisioner
EOF

kind create cluster \
  --name kind \
  --image=kindest/node:${NODE_VERSION} \
  --config=kind-calico.yaml

kind get clusters

# Helm 저장소 추가
helm repo add projectcalico https://docs.tigera.io/calico/charts

# 저장소 최신화
helm repo update

# tigera-operator 네임스페이스 생성
kubectl create namespace calico-system

# 2. Helm 설치
helm install calico projectcalico/tigera-operator \
  --version v3.29.1 \
  --namespace calico-system \
  --create-namespace \
  --set "installation.calicoNetwork.ipPools[0].cidr=10.10.0.0/16"

# 3. 중요: Operator가 준비될 때까지 대기
kubectl wait --namespace calico-system \
  --for=condition=ready pod \
  --selector=k8s-app=tigera-operator \
  --timeout=90s

# 4. Calico 시스템 Pod 생성 확인
kubectl get pods -n calico-system
