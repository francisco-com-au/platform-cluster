# ArgoCD

This installs a basic instance of ArgoCD and exposes it under https://argocd.this/ (insecure)

It offers 2 overlays (`dev` and `prod`).
Prod also creates an Ingress in https://argocd.francisco.com.au/ (secure)

# What is this for?
You will normally have 2 clusters, one for `dev` and another one for `prod`. This repo lets you install ArgoCD using a simple `kubectl apply -k` command.