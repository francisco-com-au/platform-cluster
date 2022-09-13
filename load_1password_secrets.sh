#!/bin/bash

set -e

eval $(op signin)

# Fetch the core pipeline credentials
op read "op://personal/Core Pipeline Credentials File/1password-credentials.json" \
    | base64 \
    | tr '/+' '_-' \
    | tr -d '=' \
    | tr -d '\n' > 1password-credentials.json
kubectl create secret generic op-credentials --from-file=1password-credentials.json -n one-password
rm 1password-credentials.json

# Fetch the token
OP_CONNECT_TOKEN=$(op read "op://personal/core pipeline access token - test/credential")
kubectl create secret generic onepassword-token --from-literal=token=$OP_CONNECT_TOKEN  -n one-password
