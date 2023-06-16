function platformApps(apps_repo, branch, apps_env) {
    return `---
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: platform-apps
  namespace: argocd
  # finalizers:
  #   - resources-finalizer.argocd.argoproj.io
spec:
  generators:
  - git:
      repoURL: https://github.com/${apps_repo}.git
      revision: ${branch}
      directories:
      - path: 'managed/apps/*'
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      project: platform-apps
      source:
        repoURL: https://github.com/${apps_repo}.git
        targetRevision: ${branch}
        path: '{{path}}/overlays/${apps_env}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{path.basename}}'
      syncPolicy:
        automated:
          selfHeal: true
          prune: true
        syncOptions:
        - CreateNamespace=true
        retry:
          limit: 0
          backoff:
            duration: 5s
            factor: 2
            maxDuration: 3m
  syncPolicy:
    preserveResourcesOnDeletion: false
`
};

module.exports = platformApps;