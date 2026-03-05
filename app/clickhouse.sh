#!/usr/bin/env bash

# 레포지토리 추가
helm repo add altinity https://altinity.github.io/clickhouse-operator
helm repo update

# Operator 및 ClickHouse Cluster 설치
helm upgrade --install clickhouse-operator altinity/altinity-clickhouse-operator \
  --namespace clickhouse \
  --create-namespace \
  --set "configs.clusters[0].name=cluster-3x1" \
  --set "configs.clusters[0].layout.shardsCount=3" \
  --set "configs.clusters[0].layout.replicasCount=1" \
  --set "configs.zookeeper.nodes[0].host=zookeeper-service" \
  --set "configs.zookeeper.nodes[0].port=2181" \
  --set "configs.templates.podTemplates[0].name=pod-template" \
  --set "configs.templates.podTemplates[0].spec.containers[0].name=clickhouse" \
  --set "configs.templates.podTemplates[0].spec.containers[0].resources.requests.memory=2Gi" \
  --set "configs.templates.podTemplates[0].spec.containers[0].resources.limits.memory=4Gi" \
  --set "configs.templates.podTemplates[0].spec.containers[0].resources.requests.cpu=1" \
  --set "configs.templates.podTemplates[0].spec.containers[0].resources.limits.cpu=2" \
  --set "configs.templates.podTemplates[0].spec.containers[0].env[0].name=CLICKHOUSE_MEMORY_LIMIT" \
  --set "configs.templates.podTemplates[0].spec.containers[0].env[0].value=8589934592" \
  --set "configs.templates.serviceTemplates[0].name=lb-service-template" \
  --set "configs.templates.serviceTemplates[0].spec.type=LoadBalancer" \
  --set "configs.templates.serviceTemplates[0].spec.ports[0].name=http" \
  --set "configs.templates.serviceTemplates[0].spec.ports[0].port=8123" \
  --set "configs.templates.serviceTemplates[0].spec.ports[1].name=tcp" \
  --set "configs.templates.serviceTemplates[0].spec.ports[1].port=9000"
