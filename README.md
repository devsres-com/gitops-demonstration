# GitOps Demonstration

Este repositório é o que eu vou usar para povoar meus clusters EKS das [lives do Twitch](https://www.twitch.tv/marcelo_devsres).

# GitOps TL;DR

* Instale o Argocd:
```
kubectl create namespace argocd 
kubectl -n argocd create -f argocd
kubectl -n argocd create -f appprojects
kubectl -n argocd create -f applications/application-system-apps-common.yaml

# Para AWS:
kubectl create -f application-system-apps-aws.yaml
``` 

* Cadastre este repositório Git no Argocd para fazer o deploy das **Applications**:
```
# Fui obrigado a usar Kustomize aqui.
# Ensino sobre isso outro dia.
$ kubectl kustomize --load-restrictor LoadRestrictionsNone argocd/repo | kubectl apply -f - 

# Ou sem o kustomize, mas também sem a chave ssh:
$ k create -f argocd/repos/
```

```
# Cria um **application** no Argocd que automaticamente criará Applications para
# todas as Applications que estiverem no diretório applications!
# Não entendeu? Talvez você deva frequentar a Live do Twitch!
kubectl -n argocd create -f applications/application-applications.yaml
```

# GitOps - versão longa

## ArgoCD

O ArgoCD conta com três "flavours" diferentes para uso:

* ArgoCD HA
* ArgoCD "normal"
* ArgoCD Core

O ArgoCD Core é uma versão simplificada do ArgoCD sem UI,  gerenciamento de usuário ou SSO.

### Instalação

```
k create namespace argocd
k -n argocd create -f reference/argocd/install.yaml
k -n argocd get secret argocd-initial-admin-secret -o json | jq -r '.data.password | @base64d' | clip.exe
k port-forward svc/argocd-server -n argocd 8080:443
k get secret -n prometheus grafana -o json | jq -r '.data."admin-password" | @base64d' | clip.exe
```

O ArgoCD cria uma senha inicial no secret **argocd-initial-admin-secret**.

```
PASSWORD="$( k -n argocd get secret argocd-initial-admin-secret -o go-template='{{.data.password | base64decode}}' )"
```

Como aprender a usar o ArgoCD (mas não o jeito de usar o Argocd!)

```
a -la gocd app create guestbook --repo https://github.com/devsres-com/gitops-demonstration.git --path argocd/manifests/guestbook/ --dest-namespace argocd-guestbook --sync-option CreateNamespace=true --dest-name in-cluster
```


### Usando Applications do tipo Helm

O maior problema de usar Helm charts como Applications do Argocd é o fato de que, se você usar um arquivo de configuração **values.yaml** para o seu chart, tanto o **Chart** quanto o **values.yaml** precisam estar **no mesmo repositório Git**.

Um caso de uso relativamente simples seria usar um repositório Helm remoto e um Git apenas para armazenar os valores, mas o ArgoCD nunca suportou e aparentemente nunca irá suportar:

> Values files must be in the same git repository as the Helm chart. The files can be in a different location in which case it can be accessed using a relative path relative to the root directory of the Helm chart.
> (https://argo-cd.readthedocs.io/en/stable/user-guide/helm/#values-files)

> You should be able to configure a values file from the UI that is a URL itself. Have you tried that?
> It's unlikely we'll be able to support both Git+Helm repo, but you could also use a requirements.yaml in a Git repo to do this.
> (https://github.com/argoproj/argo-cd/issues/2789#issuecomment-560496612)


#### Links simbólicos não funcionam

Você pode ficar tentado a criar um layout de pastas da seguinte forma:

```
helm/system/haproxy-ingress
|-- haproxy-ingress -> haproxy-ingress-0.13.4
|-- haproxy-ingress-0.13.4
```

Criar um objeto Application apontando para o link simbólico haproxy-ingress **não irá funcionar**. Logo, a única maneira de versionar é literalmente despejar o helm chart inteiro no diretório.


