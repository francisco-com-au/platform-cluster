#!/bin/bash

set -e

CONTAINER_REGISTRY_PROJECT=tf-ops-cicd-97aadd
SA_NAME=container-registry-pull
FILE_NAME=pull_key.json

# Make key if not exists locally
ls $FILE_NAME* || gcloud iam service-accounts keys create $FILE_NAME \
    --iam-account $SA_NAME@$CONTAINER_REGISTRY_PROJECT.iam.gserviceaccount.com \
    --project $CONTAINER_REGISTRY_PROJECT

# Make a .dockerconfigjson file with the key
key_content=$(cat $FILE_NAME | sed -r 's/"/\\"/g') # escape quotes: "{"key": "value"}" > "{\"key\":\"value\"}"
auth="{_json_key:$key_content}"
auth64=$(echo -n $auth | base64)
dockerconfigjson="{\"auths\":{\"https://gcr.io\":{\"username\":\"_json_key\",\"password\":\"$key_content\",\"auth\":\"$auth64\"}}}"
echo $dockerconfigjson > .dockerconfigjson

# Load key into 1password
secret_name="tf.ops.cicd.gcr.pull"
vault="automation"
eval $(op signin)
exists=false
op item get --vault $vault $secret_name && exists=true || exists=false
if [[ "$exists" == "true" ]]; then
    echo Edit
    op item edit \
        --vault=$vault \
        $secret_name \
        '\.dockerconfigjson[file]=./.dockerconfigjson'
else
    echo Create
    op item create --category="API Credential" \
        --title=$secret_name \
        --vault=$vault \
        '\.dockerconfigjson[file]=./.dockerconfigjson'
fi


# # Google Cloud Container registry auth
# namespaces=$(kubectl get namespaces | grep -v kube | grep Active | awk '{print $1}')
# for NAMESPACE in $namespaces; do
#     kubectl -n $NAMESPACE create secret docker-registry container-registry-pull \
#         --docker-server=https://gcr.io \
#         --docker-username=_json_key \
#         --docker-password="$(cat ./$FILE_NAME)"
#     kubectl -n $NAMESPACE patch serviceaccount default -p '{"imagePullSecrets": [{"name": "container-registry-pull"}]}'
# done