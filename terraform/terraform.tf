terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.8.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}

provider "aws" {
}

provider "tls" {
}


