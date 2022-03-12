#!/bin/bash

echo 'Este comando irá:
* fazer o deploy do ArgoCD neste cluster
* e configurar o repositório https://github.com/devsres-com/gitops-demonstration.
'

DRY_RUN=${DRY_RUN:-true}
if [ "$DRY_RUN" == false ]; then
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    kubectl kustomize --load-restrictor LoadRestrictionsNone | kubectl apply -f -
    kubectl create -f ../applications/application-apps-podinfo.yaml
    kubectl create -f ../applications/application-ingress-nginx.yaml
    kubectl create -f ../applications/application-ingress-haproxy.yaml
else
    echo 'Por precaução, este script está configurado com DRY_RUN=true.'
    echo 'Para que ele realmente faça algo, digite:'
    echo "DRY_RUN=false $0"

    echo -e 'Comandos que serão executados:\n'
    echo 'kubectl create namespace argocd'
    echo 'kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml'
    echo 'kubectl kustomize --load-restrictor LoadRestrictionsNone | kubectl apply -f -'

fi

