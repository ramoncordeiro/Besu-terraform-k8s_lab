# =============================================================================
# terraform/cloud/providers.tf
# =============================================================================
# Define quais "providers" (plugins) o Terraform precisa baixar para criar
# recursos na AWS e para gerar a chave SSH.
#
# Provider AWS: cria EC2, Security Group, Key Pair...
# Provider TLS:  gera chaves RSA localmente (privada + pública).
#                 A pública vai pra AWS. A privada fica no teu PC/workflow.
# =============================================================================

terraform {
  required_version = ">= 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
