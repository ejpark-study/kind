#!/usr/bin/env bash

# docker pull starrocks/be-ubuntu:3.5-latest
# docker pull starrocks/fe-ubuntu:3.5-latest

# docker save starrocks/be-ubuntu:3.5-latest > images/starrocks-be.tar
# docker save starrocks/fe-ubuntu:3.5-latest > images/starrocks-fe.tar

echo "kind load image-archive"
kind load image-archive images/starrocks-fe.tar --name kind
kind load image-archive images/starrocks-be.tar --name kind

# 레포지토리 추가
helm repo add starrocks https://starrocks.github.io/starrocks-kubernetes-operator

# 레포지토리 업데이트
helm repo update

# helm uninstall starrocks -n starrocks

FE_REPLICAS=1
BE_REPLICAS=3
STORAGE_SIZE=70Gi
echo "REPLICAS: $REPLICAS, STORAGE_SIZE: $STORAGE_SIZE"

helm upgrade --install starrocks starrocks/kube-starrocks \
  --namespace starrocks \
  --create-namespace \
  --set starrocks.starrocksFESpec.replicas=${FE_REPLICAS} \
  --set starrocks.starrocksFESpec.resources.requests.cpu=2 \
  --set starrocks.starrocksFESpec.resources.requests.memory=4Gi \
  --set starrocks.starrocksFESpec.resources.limits.memory=4Gi \
  --set starrocks.starrocksFESpec.storageSpec.name=fe-meta \
  --set starrocks.starrocksFESpec.storageSpec.storageSize=20Gi \
  --set starrocks.starrocksFESpec.storageSpec.storageClassName=standard \
  --set starrocks.starrocksFESpec.service.type=LoadBalancer \
  --set starrocks.starrocksBeSpec.replicas=${BE_REPLICAS} \
  --set starrocks.starrocksBeSpec.resources.requests.cpu=4 \
  --set starrocks.starrocksBeSpec.resources.requests.memory=4Gi \
  --set starrocks.starrocksBeSpec.resources.limits.memory=4Gi \
  --set starrocks.starrocksBeSpec.storageSpec.name=be-data \
  --set starrocks.starrocksBeSpec.storageSpec.storageSize=${STORAGE_SIZE} \
  --set starrocks.starrocksBeSpec.storageSpec.storageClassName=standard

# 1. 실제 리소스 이름 확인
kubectl get starrockscluster -n starrocks

# 2. 확인된 이름으로 상세 정보 조회 (보통 'kube-starrocks'일 겁니다)
kubectl describe starrockscluster kube-starrocks -n starrocks

kubectl get starrockscluster kube-starrocks -n starrocks -o yaml

kubectl get pv,pvc

kubectl get pods -n starrocks

kubectl get svc -n starrocks

# # FE Pod 이름을 환경변수로 저장 (보통 starrocks-fe-0 형태)
# export FE_POD=$(kubectl get pods -n starrocks -l "starrocks.com/table-name=fe" -o jsonpath='{.items[0].metadata.name}')
# echo "FE_POD: $FE_POD"

# # Pod 내부로 들어가서 MySQL 접속 (기본 계정: root, 패스워드 없음)
# kubectl exec -it $FE_POD -n starrocks -- mysql -P 9030 -h 127.0.0.1
