#!/usr/bin/env bash

helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/

# helm show values headlamp/headlamp > headlamp-values.yaml

# 네임스페이스 생성 및 설치
kubectl create namespace headlamp

helm upgrade --install headlamp headlamp/headlamp \
  --namespace headlamp \
  --create-namespace \
  --set service.type=LoadBalancer \
  --set service.port=80

# 1. 관리자용 서비스 어카운트 생성
kubectl create serviceaccount headlamp-admin -n headlamp

# 2. 클러스터 관리자 권한 부여
kubectl create clusterrolebinding headlamp-admin-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=headlamp:headlamp-admin

# 3. 토큰 생성 및 확인 (이 값을 복사해서 로그인창에 입력)
kubectl create token headlamp-admin -n headlamp

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=headlamp -n headlamp --timeout=60s

# 2. Get the token using
# kubectl create token headlamp --namespace headlamp

export SERVICE_IP=$(kubectl get svc --namespace headlamp headlamp --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
echo http://$SERVICE_IP:80