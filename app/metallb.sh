#!/usr/bin/env bash


# see what changes would be made, returns nonzero returncode if different
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl diff -f - -n kube-system

# actually apply the changes, returns nonzero returncode on errors only
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system

# MetalLB 네임스페이스 및 리소스 생성
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.3/config/manifests/metallb-native.yaml

# MetalLB with helm
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb

kubectl get pods -n metallb-system

kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s

# IP 대역 확인 (보통 172.18.0.x 대역임)
IP_PREFIX=$(docker network inspect kind -f '{{range .IPAM.Config}}{{.Subnet}} {{end}}' | grep -oE '[0-9]+\.[0-9]+' | head -n 1)
echo "IP_PREFIX: ${IP_PREFIX}"

# IP Pool 설정 (예: 172.18.255.200 ~ 250)
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: example-pool
  namespace: metallb-system
spec:
  addresses:
  - ${IP_PREFIX}.255.200-${IP_PREFIX}.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: empty
  namespace: metallb-system
EOF

kubectl get ipaddresspool -n metallb-system

kubectl get svc -n istio-system
