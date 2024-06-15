#!/bin/bash

# Deploy Kubernetes resources
kubectl apply -f nginx-config.yaml
kubectl apply -f k8s-deployment.yaml
kubectl apply -f k8s-service.yaml

# Get the LoadBalancer URL
echo "Waiting for the LoadBalancer to get an external IP..."
sleep 120
kubectl get services