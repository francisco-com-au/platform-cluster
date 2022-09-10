#!/bin/bash

set -e

ENVIRONMENT=$1
TYPE=$2

function type_minikube() {
    brew install minikube
    minikube config set memory 8192
    minikube config set cpus 6
    minikube start
    minikube addons enable ingress
}

function type_k3d() {
    brew install k3d
    # Create registry
    k3d registry create platform-$ENVIRONMENT.localhost --port 12345

    # Create cluster
    k3d cluster create \
        platform-$ENVIRONMENT \
        --registry-use k3d-platform-$ENVIRONMENT.localhost:12345 \
        --k3s-arg '--no-deploy=traefik@server:*' -p "80:80@loadbalancer" -p "443:443@loadbalancer"
}

if [ "$TYPE" == "k3d" ]; then
    type_k3d
elif [ "$TYPE" == "minikbue" ]; then
    type_minikube
else
    echo "Cluster type not specified. Defaulting to k3d."
fi
