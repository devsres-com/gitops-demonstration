# GitOps

## ArgoCD

O ArgoCD conta com três "flavours" diferentes para uso:

* ArgoCD HA
* ArgoCD "normal"
* ArgoCD Core

O ArgoCD Core é uma versão simplificada do ArgoCD sem UI,  gerenciamento de usuário ou SSO.

### Instalação

```
k create namespace argocd
k -n argocd create -f install.yaml
k port-forward svc/argocd-server -n argocd 8080:443
```

O ArgoCD cria uma senha inicial no secret **argocd-initial-admin-secret**.

```
PASSWORD="$( k -n argocd get secret argocd-initial-admin-secret -o go-template='{{.data.password | base64decode}}' )"
```


