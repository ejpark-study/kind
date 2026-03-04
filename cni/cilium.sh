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

cat <<EOF > kind-cilium.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

kubeadmConfigPatches:
- |
  apiVersion: kubelet.config.k8s.io/v1beta1
  kind: KubeletConfiguration
  evictionHard:
    nodefs.available: "0%"

# MetalLB 등 로드밸런서 연동 시 필수 설정
# - |
#   apiVersion: kubeproxy.config.k8s.io/v1alpha1
#   kind: KubeProxyConfiguration
#   mode: "ipvs"
#   ipvs:
#     strictARP: true

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
  kubeProxyMode: "none" 
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
- role: worker
  extraMounts:
  - hostPath: ${VOLUME_PATH}/worker1/data
    containerPath: /var/local-path-provisioner
- role: worker
  extraMounts:
  - hostPath: ${VOLUME_PATH}/worker2/data
    containerPath: /var/local-path-provisioner
- role: worker
  extraMounts:
  - hostPath: ${VOLUME_PATH}/worker3/data
    containerPath: /var/local-path-provisioner
EOF

kind create cluster \
  --name kind \
  --image=kindest/node:${NODE_VERSION} \
  --config=kind-cilium.yaml

kind get clusters

# CNI: Cilium
export KUBE_API_SERVER_IP=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o yaml | yq '.items[0].status.addresses[] | select(.type=="InternalIP").address');
export KUBE_API_SERVER_PORT=6443;

echo "KUBE_API ${KUBE_API_SERVER_IP}:${KUBE_API_SERVER_PORT}"

read -p "CNI: Cilium 설치를 진행하시겠습니까? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    exit 1
fi

cilium install \
  --set externalIPs.enabled=true \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set ingressController.enabled=true \
  --set ingressController.loadbalancerMode=shared \
  --set k8sServiceHost=${KUBE_API_SERVER_IP} \
  --set k8sServicePort=${KUBE_API_SERVER_PORT} \
  --set kubeProxyReplacement=true \
  --set l2announcements.enabled=true \
  --set loadBalancer.l7.backend=envoy \
  --set cni.exclusive=false # with istio

cilium status --wait

kubectl get nodes -o wide

kubectl get svc -n kube-system cilium-ingress

kubectl get svc -n kube-system hubble-ui

# 도커 네트워크 서브넷 확인
echo "Docker network inspect"
docker network inspect kind | jq '.[].IPAM.Config'

# L2 알림 정책 설정 (CiliumL2AnnouncementPolicy)
cat <<EOF | kubectl apply -f -
apiVersion: "cilium.io/v2alpha1"
kind: CiliumL2AnnouncementPolicy
metadata:
  name: l2-policy
  namespace: kube-system
spec:
  externalIPs: true
  loadBalancerIPs: true
EOF

kubectl describe ciliuml2announcementpolicies -n kube-system

# CiliumLoadBalancerIPPool 설정 (도커 네트워크 172.16.1.0/24 범위 내 미사용 대역)
cat <<EOF | kubectl apply -f -
apiVersion: "cilium.io/v2"
kind: CiliumLoadBalancerIPPool
metadata:
  name: ipam
  namespace: kube-system
spec:
  blocks: # docker subnet: 172.16.1.0/24
    - cidr: 172.16.1.64/26 # 172.16.1.64 ~ 172.16.1.127
    - start: "172.16.1.200"
      stop: "172.16.1.240"
EOF

kubectl describe ippools -n kube-system 

# CiliumNodeConfig 설정
cat <<EOF | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNodeConfig
metadata:
  name: l2-announcements-config
  namespace: kube-system
spec:
  nodeSelector:
    matchLabels: {}
  defaults:
    l2-announcements-all-interfaces: "true"
EOF

kubectl describe ciliumnodeconfig -n kube-system 

kubectl describe ciliumnodes -n kube-system 

kubectl get ciliuml2announcementpolicies,ciliumloadbalancerippools,ciliumnodeconfig,ciliumnodes -n kube-system

# kubectl api-resources --api-group='cilium.io'
# kubectl get crd | grep cilium
