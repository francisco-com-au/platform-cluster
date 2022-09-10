# Platform Clusters ⎈

Want to spin up a brand new environment? This repo has the code to create a Kubernetes cluster and configure it to run applications in a specific environment.

This goes hand in hand with the [Core Pipeline](https://github.com/francisco-com-au/core-pipeline). In the core pipeline repo you define applications and environments. In this repo you spin up clusters to run such evironments.

In a nutshell, this will point to the [Platform Apps](https://github.com/francisco-com-au/platform-apps) repo, using overlays to select environments.

# How do I use it?
Configure your host file
- Add the line `127.0.0.1 argocd.this` to `/etc/hosts`
- Add the line `127.0.0.1 k3d-platform-{{ENV NAME}}.localhost` to `/etc/hosts`

Run `./main.sh <environment_name>`. It will:
- create a local cluster using [`K3D`](https://k3d.io/v5.4.6/) ([`k3s`](https://github.com/k3s-io/k3s) in [`docker`](https://www.docker.com/) which works great for forwarding traffic)
- install [`ArgoCD`](https://argo-cd.readthedocs.io/en/stable/)
- configure [`ArgoCD`](https://argo-cd.readthedocs.io/en/stable/) to watch the [`Platform Apps`](https://github.com/francisco-com-au/platform-apps) repo on specific overlays based on the environment.


# Dependencies
- [`homebrew`](https://brew.sh/)
- [`node`](https://nodejs.org/en/download/)

Oh, by the way! This is intended to run on a local Mac, that's why I'm using `brew`.