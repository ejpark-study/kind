#!/usr/bin/env bash

# Istio 공식적 프로필
# - default: 권장되는 프로덕션 설정.
# - demo: 학습 및 시연용 (기능이 가장 많이 켜지며, 리소스를 좀 더 먹습니다).
# - minimal: 필수 기능만 포함.
# - remote: 멀티 클러스터용.

istioctl install -y \
	--set profile=default \
	--set components.cni.enabled=true \
	--set components.cni.namespace=kube-system \
	--set values.cni.cniBinDir=/opt/cni/bin \
	--set values.cni.cniConfDir=/etc/cni/net.d \
	--set values.sidecarInjectorWebhook.rewriteAppHTTPProbe=true

kubectl get pods -n kube-system -l app=istio-cni-node

# 네임스페이스에 사이드카 자동 주입 설정
kubectl label namespace default istio-injection=enabled

# Kiali
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  -n istio-system \
  --create-namespace \
  --set prometheus.service.type=ClusterIP

# kiali
helm repo add kiali https://kiali.org/helm-charts

helm repo update

helm upgrade --install \
    --namespace kiali-operator \
    --create-namespace \
    --set cr.create=true \
    --set cr.namespace=istio-system \
    --set cr.spec.auth.strategy="anonymous" \
    --set cr.spec.external_services.prometheus.url="http://prometheus-kube-prometheus-prometheus.istio-system:9090" \
    kiali-operator \
    kiali/kiali-operator

# helm show values kiali/kiali-operator
# kubectl rollout restart deployment kiali -n istio-system

kubectl wait --for=condition=Available deployment/kiali-operator -n kiali-operator --timeout=120s

kubectl wait --for=condition=Ready pod -l app=kiali -n istio-system --timeout=300s

istioctl dashboard kiali