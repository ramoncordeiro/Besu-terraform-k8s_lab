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

#find a way to hidden the full path