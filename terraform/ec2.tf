# Para acessar amáquina via SSM, precisamos de uma role.
resource "aws_iam_policy" "eks_viewer" {
  name        = "eks_viewer"
  path        = "/"
  description = "Lista coisas do EKS"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeNodegroup",
                "eks:ListNodegroups",
                "eks:DescribeCluster",
                "eks:ListClusters",
                "eks:AccessKubernetesApi",
                "ssm:GetParameter",
                "eks:ListUpdates",
                "eks:ListFargateProfiles"
            ],
            "Resource": "*"
        }
    ]  
  })
}

resource "aws_iam_policy" "session_manager" {
  name        = "session_manager"
  path        = "/"
  description = "Acesso à máquina por meio do Session Manager"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:UpdateInstanceInformation",
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetEncryptionConfiguration"
            ],
            "Resource": "*"
        }
    ]
  })
}

data "aws_iam_policy_document" "session_manager" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "session_manager" {
  assume_role_policy = data.aws_iam_policy_document.session_manager.json
  name               = "DevSresSessionManager"
}

resource "aws_iam_role_policy_attachment" "session_manager" {
  role       = aws_iam_role.session_manager.name
  policy_arn = aws_iam_policy.session_manager.arn 
}

resource "aws_iam_role_policy_attachment" "eks_viewer" {
  role       = aws_iam_role.session_manager.name
  policy_arn = aws_iam_policy.eks_viewer.arn 
}


resource "aws_iam_instance_profile" "session_manager" {
  name = "session_manager"
  role = aws_iam_role.session_manager.name
}

output session_manager_role {
  value = aws_iam_role.session_manager.arn
}

# VM:

# Para jogar o valor no template
data "aws_region" "current" {}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.20220406.1-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] 
}

resource "aws_instance" "kubectl" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.nano"
	iam_instance_profile = aws_iam_instance_profile.session_manager.name
  user_data_replace_on_change = true 
  user_data   = base64encode(
                  templatefile(
                      "templates/user_data.tmpl",{ 
                          "eks_cluster_name" = var.eks_cluster_name,
                          "aws_region" = data.aws_region.current.name
                    }
                  )
                )
  tags = {
    "Name" = "kubectl-bastion"
  }
}

output ec2_instance {
  value = aws_instance.kubectl.id
}

output aws_region {
  value = data.aws_region.current.name
}
