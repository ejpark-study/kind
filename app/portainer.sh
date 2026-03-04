#!/usr/bin/env bash

helm repo add portainer https://portainer.github.io/k8s/

helm repo update

helm install --create-namespace -n portainer portainer portainer/portainer

kubectl get all -n portainer

helm list --all-namespaces

kubectl port-forward -n portainer svc/portainer 30777:9000
