#!/bin/bash

set -e

ENVIRONMENT=$1
if [ "$ENVIRONMENT" == "" ]; then
  # Set the environment depending on the current branch
  branch=$(git rev-parse --abbrev-ref HEAD)
  if [ "$branch" == "main" ]; then
    export ENVIRONMENT=prod
  elif [ "$branch" == "develop" ]; then
    export ENVIRONMENT=dev
  else
    echo "Unknown branch: $branch"
    exit 1
  fi
fi
echo "Environment: $ENVIRONMENT"

# Create cluster
./cluster.sh $ENVIRONMENT k3d

# Install argocd
./argocd.sh $ENVIRONMENT
