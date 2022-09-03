function platformApps(apps_repo, branch, env) {
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
      - path: 'managed/*'
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      project: platform-apps
      source:
        repoURL: https://github.com/${apps_repo}.git
        targetRevision: ${branch}
        path: '{{path.basename}}/overlays/${env}'
      destination:
        server: https://kubernetes.default.svc
        namespace: argocd
      syncPolicy:
        automated:
          selfHeal: true
          prune: true
        syncOptions:
        - CreateNamespace=true
`
};

module.exports = platformApps;