# 
# Variables - isso deveria estar em um arquivo separado
# 
variable eks_cluster_name {
    type = string
    description = "Nome do cluster EKS"
    default = "devsres-lab"    
}

# 
# Data
# 

# Tenho que deixar de preguiça e passar a subir o EKS com Terraform. 
# Esse data aqui tem que morrer.
data "aws_eks_cluster" "controller" {
  name = var.eks_cluster_name 
}

# Chega a ser difícil de explicar como uma coisa tão simples deixar alguém tão feliz.
# Simplesmente **não havia** como recuperar a informação de thumbprint dos certificados do EKS
# sem precisar recorrer a um monte de hacks e shell scripts
# * https://github.com/hashicorp/terraform-provider-aws/issues/10104
#
# Eu precisei fazer um desses hacks em 2019.
# Este recurso *resolveu*:
# * https://github.com/hashicorp/terraform-provider-tls/pull/62
# 
# Obrigado Hashicorp!
data "tls_certificate" "controller" {
  url = data.aws_eks_cluster.controller.identity[0].oidc[0].issuer
}

#
# Resources 
# 

# Quer saber de onde vem esse "this"?
# https://www.terraform-best-practices.com/naming#resource-and-data-source-arguments
resource "aws_iam_openid_connect_provider" "eks_controller" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.controller.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.controller.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "cwagent" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

	# Se você lembrar, semana passada eu usei a variável com este sed para remover o https:
    # export OIDC_URL="$( aws eks describe-cluster --name devsres-lab --query 'cluster.identity.oidc.issuer' --output text | sed 's#https://##' )"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_controller.url, "https://", "")}:sub"
      values   = [  "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent",
					"system:serviceaccount:amazon-cloudwatch:fluent-bit"
				 ]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_controller.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "cwagent" {
  assume_role_policy = data.aws_iam_policy_document.cwagent.json
  name               = "DevSresEKS_cwagent"
}

resource "aws_iam_role_policy_attachment" "cwagent_cloudwatch" {
  role       = aws_iam_role.cwagent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy" 
}

output "cwagent_role_arn" {
  value = aws_iam_role.cwagent.arn
}
