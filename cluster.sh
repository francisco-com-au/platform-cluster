#!/bin/bash

set -e

ENVIRONMENT=$1
TYPE=$2
if [ "$TYPE" == "k3d" ]; then
    type_k3d
elif [ "$TYPE" == "minikbue" ]; then
    type_minikube
else
    echo "Cluster type not specified. Defaulting to k3d."
fi

function type_minikube() {
    brew install minikube
    minikube config set memory 8192
    minikube config set cpus 6
    minikube start
    minikube addons enable ingress
}

function type_k3d() {
    brew install k3d
    k3d cluster create platform-$ENVIRONMENT --k3s-arg '--no-deploy=traefik@server:*' -p "80:80@loadbalancer" -p "443:443@loadbalancer"
}

type_k3d