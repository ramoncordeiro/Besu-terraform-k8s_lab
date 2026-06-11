terraform {
  required_version = ">= 1.15.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.5"
    }
  }
}


provider "kubernetes" {
  config_path = pathexpand(var.kubeconfig_path)
}