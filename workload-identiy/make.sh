#!/bin/bash

set -e

# This scripts contains all the steps needed to create a cluster with federated identity.

rm -rf generated
mkdir generated

# ------- Pre requisites (one-off)-------------------------------------------
# Create keys that the cluster will use to sign service accounts
openssl genrsa -out generated/sa.key 2048
openssl rsa -in generated/sa.key -pubout -out generated/sa.pub

# Create a jws file from the public key
python3 make_jwk.py

# ------- Google stuff (one-off) --------------------------------------------
PROJECT_ID=ab-aa-api-dev-c34247
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
echo $PROJECT_ID > generated/project_id
echo $PROJECT_NUMBER > generated/project_number

# Create a Workload Identity Pool
POOL_ID=$(echo "federated-pool-$(date +%s)")
echo $POOL_ID > generated/pool_id
POOL_DESCRIPTION="Test pool for federated identity"
POOL_DISPLAY_NAME="Federated Pool"
gcloud iam workload-identity-pools create $POOL_ID \
    --project=$PROJECT_ID \
    --location="global" \
    --description="$POOL_DESCRIPTION" \
    --display-name="$POOL_DISPLAY_NAME"

# Add the Kubernetes cluster as a workload identity pool provider and upload the cluster's JWKS
PROVIDER_ID=k3d-cluster
echo $PROVIDER_ID > generated/provider_id
ISSUER="https://american-broomstick.com.au"
gcloud iam workload-identity-pools providers create-oidc $PROVIDER_ID \
    --project=$PROJECT_ID \
    --location="global" \
    --workload-identity-pool="$POOL_ID" \
    --issuer-uri="$ISSUER" \
    --allowed-audiences="google-cloud.american-broomstick.com.au" \
    --attribute-mapping="google.subject=assertion.sub" \
    --jwk-json-path="generated/jwk.json"

# Create a credential configuration file
gcloud iam workload-identity-pools create-cred-config \
    projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_ID/providers/$PROVIDER_ID \
    --credential-source-file=/var/run/service-account/token \
    --credential-source-type=text \
    --output-file=credential-configuration.json

mv credential-configuration.json generated/

# ------- Make cluster (one per cluster) --------------------------------------
CLUSTER_NAME=$(echo "test-$(date +%s)")
KEYS_LOCAL_PATH=~/credentials/k3d/$CLUSTER_NAME
rm -rf $KEYS_LOCAL_PATH
mkdir -p $KEYS_LOCAL_PATH
cp -r generated/sa.key $KEYS_LOCAL_PATH
cp -r generated/sa.pub $KEYS_LOCAL_PATH
cp -r generated/credential-configuration.json $KEYS_LOCAL_PATH

# Make the cluster
k3d cluster create $CLUSTER_NAME \
  --verbose \
  --agents 2 \
  -p "8080:80@loadbalancer" \
  -p "8443:443@loadbalancer" \
  --volume $KEYS_LOCAL_PATH/:/keys/ \
  --api-port 6443 \
  --k3s-arg "--kube-apiserver-arg=--service-account-issuer=$ISSUER@server:*" \
  --k3s-arg "--kube-apiserver-arg=--service-account-signing-key-file=/keys/sa.key@server:*" \
  --k3s-arg "--kube-apiserver-arg=--service-account-key-file=/keys/sa.pub@server:*" \

# Mount the federation file
NAMESPACE=default
CONFIGMAP_NAME=gcp-workload-identity-config
kubectl create configmap $CONFIGMAP_NAME \
  --from-file generated/credential-configuration.json \
  --namespace $NAMESPACE

# ------- IAM (one per workload) --------------------------------------
WORKLOAD_ID=bucket-ls

# Make a kube service account
kubectl create serviceaccount $WORKLOAD_ID --namespace $NAMESPACE

# Grant GCP roles to the federated kube service account
MAPPED_SUBJECT=system:serviceaccount:$NAMESPACE:$WORKLOAD_ID
gcloud projects add-iam-policy-binding \
    projects/$PROJECT_ID \
    --role=roles/storage.objectViewer \
    --member=principal://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL_ID/subject/$MAPPED_SUBJECT \
    --condition=None

# Create a deployment
kubectl apply -f deployment.yaml