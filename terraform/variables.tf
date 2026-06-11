variable "genesis_json_path" {
  description = "path genesis.json"
  type        = string
}

variable "static_nodes_json_path" {
  description = "caminho pra static-nodes.json"
  type        = string
}

variable "nodes" {
  description = "Mapa de nos da rede Besu"
  type = map(object({
    name = string
    type = string
  }))
}

variable "kubeconfig_path" {
  description = "path to kubeconfig file to connect to the Kubernetes cluster"
  type        = string
  default     = "/etc/rancher/k3s/k3s.yaml"
}