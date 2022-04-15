# EKS

A AWS gosta de dificultar as coisas.

```
export CLUSTER=devsres-lab ; 
eksctl create cluster         \
--name "$CLUSTER"             \
--vpc-nat-mode Disable        \
--zones us-west-2a,us-west-2b \
--nodegroup-name ng1          \
--instance-types t3.medium    \
--nodes-min 0                 \
--nodes-max 5                 \
--nodes 3
```

Ops, esqueci de habilitar o OIDC provider.

```
eksctl utils associate-iam-oidc-provider --cluster $CLUSTER --approve
```

Vamos aproveitar e pegar a URL, porque vamos precisar dela... MUITO!

```
export OIDC_URL="$( aws eks describe-cluster --name devsres-lab --query 'cluster.identity.oidc.issuer' --output text | sed 's#https://##' )"
```

Também vamos precisar do OIDC_URL.

```
export ACCOUNT_ID="$( aws sts get-caller-identity --query Arn --output text | cut -f-5 -d: )"
```

## Criando a role para o cwagent

```
# Vamos criar uma policy antes:

POLICY1="$( aws iam create-policy \
                 --policy-name DevSresEKS_describeEBS_Policy \
                 --policy-document file://utils/aws/eks/ebs-describevolumes-policy.json \
                 --query "Policy.Arn" --output text )"
POLICY2="arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"

export NS=amazon-cloudwatch

for i in cloudwatch-agent fluent-bit; do

  export SA=$i
  envsubst < utils/aws/eks/assume-role-policy-document.json.template \
  >  utils/aws/eks/$SA-assume-role-policy-document.json
  ROLE_NAME="DevSresEKS_CWAGENT_$SA"
  ROLE_ARN="$( aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file://utils/aws/eks/cloudwatch-agent-assume-role-policy-document.json --query Role.Arn --output text )"
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY1"
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY2"
  
  kubectl -n $NS annotate serviceaccount $SA "eks.amazonaws.com/role-arn=$ROLE_ARN" --overwrite=true
  

done

```

