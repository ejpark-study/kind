#!/usr/bin/env bash

POD_SUBNET=10.244.0.0/16
SVC_SUBNET=10.11.0.0/16

cat <<EOF | kind create cluster --name kind --image=kindest/node:v1.35.0 --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

kubeadmConfigPatches:
- |
  apiVersion: kubelet.config.k8s.io/v1beta1
  kind: KubeletConfiguration
  evictionHard:
    nodefs.available: "0%"
- |
  apiVersion: kubeproxy.config.k8s.io/v1alpha1
  kind: KubeProxyConfiguration
  mode: "ipvs"        # IPVS 모드 활성화
  ipvs:
    strictARP: true   # MetalLB 등 로드밸런서 연동 시 필수 설정

kubeadmConfigPatchesJSON6902:
- group: kubeadm.k8s.io
  version: v1beta3
  kind: ClusterConfiguration
  patch: |
    - op: add
      path: /apiServer/certSANs/-
      value: kind 

networking:
  disableDefaultCNI: true # Flannel 설치를 위해 기본 CNI 비활성화
  podSubnet: "${POD_SUBNET}" # Flannel 기본 대역
  serviceSubnet: "${SVC_SUBNET}"

nodes:
- role: control-plane
  labels:
    name: control-plane
    istio: ingressgateway # Istio Gateway 배치를 위한 레이블
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    listenAddress: "0.0.0.0"
  - containerPort: 443
    hostPort: 443
    listenAddress: "0.0.0.0"
- role: worker
- role: worker
- role: worker
EOF

# 설치 순서 (Flannel -> MetalLB -> Istio)

# Flannel 설치
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

kubectl wait --for=condition=Ready nodes --all --timeout=300s

# 1. CNI 플러그인 바이너리 다운로드 및 모든 노드에 설치
# (v1.4.0은 v1.35.0 노드의 아키텍처와 잘 호환됩니다)
for node in $(kind get nodes); do
  echo "Installing CNI bridge plugins on $node..."
  docker exec -it "$node" bash -c "
    curl -L https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz -o /tmp/cni-plugins.tgz && \
    tar -xzf /tmp/cni-plugins.tgz -C /opt/cni/bin && \
    rm /tmp/cni-plugins.tgz
  "
done
