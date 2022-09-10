#!/bin/bash

CONTAINER_REGISTRY_PROJECT=tf-ops-cicd-97aadd
SA_NAME=container-registry-pull
FILE_NAME=pull_key.json

# Make key if not exists locally
ls $FILE_NAME* || gcloud iam service-accounts keys create $FILE_NAME \
    --iam-account $SA_NAME@$CONTAINER_REGISTRY_PROJECT.iam.gserviceaccount.com \
    --project $CONTAINER_REGISTRY_PROJECT


# Google Cloud Container registry auth
namespaces=$(kubectl get namespaces | grep -v kube | grep Active | awk '{print $1}')
for NAMESPACE in $namespaces; do
    kubectl -n $NAMESPACE create secret docker-registry container-registry-pull \
        --docker-server=https://gcr.io \
        --docker-username=_json_key \
        --docker-password="$(cat ./$FILE_NAME)"
    kubectl -n $NAMESPACE patch serviceaccount default -p '{"imagePullSecrets": [{"name": "container-registry-pull"}]}'
done