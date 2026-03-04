#!/usr/bin/env bash

# docker pull starrocks/be-ubuntu:3.5-latest
# docker save starrocks/be-ubuntu:3.5-latest > starrocks-be.tar

# docker pull starrocks/fe-ubuntu:3.5-latest
# docker save starrocks/fe-ubuntu:3.5-latest > starrocks-fe.tar

kind load image-archive starrocks-fe.tar --name kind
kind load image-archive starrocks-be.tar --name kind

# 레포지토리 추가
helm repo add starrocks https://starrocks.github.io/starrocks-kubernetes-operator

# 레포지토리 업데이트
helm repo update

helm uninstall starrocks -n starrocks

helm upgrade --install starrocks starrocks/kube-starrocks \
  --namespace starrocks \
  --create-namespace \
  --set starrocks.starrocksFESpec.replicas=1 \
  --set starrocks.starrocksFESpec.resources.requests.cpu=1 \
  --set starrocks.starrocksFESpec.resources.requests.memory=2Gi \
  --set starrocks.starrocksFESpec.storageSpec.name=fe-meta \
  --set starrocks.starrocksFESpec.storageSpec.storageSize=10Gi \
  --set starrocks.starrocksFESpec.storageSpec.storageClassName=standard \
  --set starrocks.starrocksFESpec.service.type=LoadBalancer \
  --set starrocks.starrocksBeSpec.replicas=3 \
  --set starrocks.starrocksBeSpec.resources.requests.cpu=1 \
  --set starrocks.starrocksBeSpec.resources.requests.memory=2Gi \
  --set starrocks.starrocksBeSpec.storageSpec.name=be-data \
  --set starrocks.starrocksBeSpec.storageSpec.storageSize=20Gi \
  --set starrocks.starrocksBeSpec.storageSpec.storageClassName=standard

# 1. 실제 리소스 이름 확인
kubectl get starrockscluster -n starrocks

# 2. 확인된 이름으로 상세 정보 조회 (보통 'kube-starrocks'일 겁니다)
kubectl describe starrockscluster kube-starrocks -n starrocks

kubectl get starrockscluster kube-starrocks -n starrocks -o yaml