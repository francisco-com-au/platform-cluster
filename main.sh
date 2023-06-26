#!/bin/bash

set -e

APP_ENV=$1
export PLATFORM_ENV=dev

# This determines what version of the platform we are using:
# - develop is for developing the platform itself
# - main is for developing applications on a stable version of the platform
branch=$(git rev-parse --abbrev-ref HEAD)
PLATFORM_ENV=$branch
# if [ "$branch" == "main" ]; then
#   export PLATFORM_ENV=prod
# elif [ "$branch" == "develop" ]; then
#   export PLATFORM_ENV=dev
# else
#   echo "Unknown branch: $branch"
#   exit 1
# fi

# If an app environment was not provided, mimic the platform env.
if [ "$APP_ENV" == "" ]; then
  APP_ENV=$PLATFORM_ENV
fi

echo "Platform Environment: $PLATFORM_ENV"
echo "Application Environment: $APP_ENV"

# Create cluster
./cluster.sh $APP_ENV k3d

# Install argocd
./argocd.sh $APP_ENV $PLATFORM_ENV

# Load 1password
./load_1password_secrets.sh

# Load pull keys
./load_pull_key.sh