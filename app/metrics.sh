#!/usr/bin/env bash

# 1. Helm 레포지토리 추가
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update

# 2. Helm 설치 (TLS 무시 및 API 가용성 설정 추가)
helm install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set args={--kubelet-insecure-tls}

kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server

# 잠시 후(약 30초~1분 뒤) 아래 명령어로 메트릭이 정상적으로 수집되는지 확인해 보세요.
kubectl wait \
  -n kube-system \
  -l app.kubernetes.io/name=metrics-server \
  --for=condition=Ready pod \
  --timeout=60s

# 노드 메트릭 확인
kubectl top node

# 포드 메트릭 확인
kubectl top pod -A
