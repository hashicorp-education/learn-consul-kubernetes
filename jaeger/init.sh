# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add jetstack https://charts.jetstack.io --force-update

helm repo update


kind delete cluster --name hashicups-jaeger
kind create cluster --name hashicups-jaeger --config ./helm/kind.yaml

helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.18.2 --set crds.enabled=true

helm install jaeger jaegertracing/jaeger-operator --version "2.57.0" --wait
helm upgrade -i jaeger jaegertracing/jaeger-operator --wait
kubectl apply -f ./helm/jaeger.yaml --wait

helm install -f ./helm/consul.yaml consul hashicorp/consul --version "1.7.1" --wait
kubectl apply -f proxy-defaults.yaml

kubectl apply -f ./ --wait