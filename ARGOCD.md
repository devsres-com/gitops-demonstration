# Tópicos

## Gestão de usuários

Você pode visualizar os usuários com o comando abaixo:

```
$ argocd account list
NAME   ENABLED  CAPABILITIES
admin  true     login
```

Mas não é possível criar usuários com o comando do ArgoCD (ou mesmo com a UI!)! Você cadastra os usuários locais em um ConfigMap (tosco!)

Você baixa o configmap argocd-cm:

```
$ kubectl -n argocd get cm argocd-cm -o yaml > cm-argocd-cm.yaml

```

E edita ele para ficar tipo isso:

```
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/name: argocd-cm
    app.kubernetes.io/part-of: argocd
  name: argocd-cm
  namespace: argocd
data:
  accounts.marcelo: apiKey, login
  accounts.automation: apiKey
```

Os nomes dos usuários vão logo depois dos accounts. Horrível, né!

Após isso, apply:

```
$ k apply -f cm-argocd-cm.yaml
```

Os usuários irão aparecer no comando anterior:

```
$ argocd account list
NAME        ENABLED  CAPABILITIES
admin       true     login
automation  true     apiKey
marcelo     true     apiKey, login
```

Eita, mas e as senhas?

Ah, as senhas você usa o comando argocd. Bizarro né.


Configurando senhas para o usuário **marcelo**:
```
# Você também pode passar a senha a linha de comando, mas isso é ainda mais tosco!
# argocd account update-password --account marcelo --new-password z0mgtcu
$ argocd account update-password --account marcelo --new-password 
*** Enter password of currently logged in user (admin):
*** Enter new password for user marcelo:
*** Confirm new password for user marcelo:
Password updated

```

Onde ficam as senhas? Na secret **argocd-secrets**:

```
apiVersion: v1
data:
  accounts.teste.password: JDJhJDEwJDAuMWNvZ201UDg2czVYTlc0SHd0RWV0SkgxMjJEUWx2L1lSMkM3RnY4MGk0b3FlaEFscUF1
  accounts.teste.passwordMtime: MjAyMi0wMi0xOVQwNjoxNzoxN1o=
  accounts.teste.tokens: bnVsbA==
  ...
kind: Secret
metadata:
  creationTimestamp: "2022-02-19T05:41:33Z"
  labels:
    app.kubernetes.io/name: argocd-secret
    app.kubernetes.io/part-of: argocd
  name: argocd-secret
  namespace: argocd
type: Opaque
```

Qual a pegadinha? Lá fica não apenas as senhas de usuários, mas várias tranqueiras essenciais para a administração do ArgoCD, tornando sua gestão declarativa quase impossível!

Pelo menos aprendeu a fazer os usuários maneira declarativa!

## SSO

É possível!
