#!/bin/bash

set -e

ENVIRONMENT=$1

PASSWORD=adminadmin
PORT=9999

# Render apps
cp -r apps rendered
cd render
export APPS_REPO="francisco-com-au/platform-apps"
export ENVIRONMENT=$ENVIRONMENT
node index.js
cd ..
mv render/applicationSet.yaml rendered/platform-apps/applicationSet.yaml

# Install kustomize
brew install kustomize

# Install Argo CD on the cluster
kubectl create namespace argocd
kubectl -n argocd apply -k ./rendered/argocd/overlays/$CLUSTER_ENV # <- dev doesn't create an external ingress

# Install platform ops apps
kubectl -n argocd apply -k ./rendered/platform-ops/overlays/$CLUSTER_ENV

# Install Argo CD CLI
brew install argocd

# Wait for the Server to be up
kubectl -n argocd rollout status deployment argocd-server

# # Install the NGINX ingress controller
# kubectl apply -k ./rendered/ingress-nginx

# Wait for nginx to be up
until kubectl -n ingress-nginx rollout status deployment ingress-nginx-controller; do
    sleep 5
done

# Initialise projects and apps
kubectl -n argocd apply -f ./rendered/platform-apps

# Update admin password (need to configure argocd.this in your host file to point to 127.0.0.1)
export PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret --output=jsonpath="{.data.password}" | base64 --decode)
argocd login argocd.this --insecure --username admin --password $PASS --grpc-web
argocd account update-password --current-password $PASS --new-password $PASSWORD

# Cleanup
rm -rf rendered