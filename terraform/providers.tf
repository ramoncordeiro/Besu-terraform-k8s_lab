terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.5"
    }
  }
}

variable "kubeconfig_path" {
  description = "path to kubeconfig file to connect to the Kubernetes cluster"
  type        = string
  default     = "/etc/rancher/k3s/k3s.yaml"
}

provider "kubernetes" {
  config_path = pathexpand(var.kubeconfig_path)
}