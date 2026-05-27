variable "node_name" {
    description = "Nome Unico para no (ps: validator01, boot,writer)"
    type = string
}

variable "node_type" {
    description = "Tipo de No (ps: validator, boot, writer, observer)"
    type = string
    default = "validator"
}

variable "genesis_configmap_name" {
    description = "genesis.json"
    type = string
}

variable "static_nodes_configmap_name" {
    description = "static-node.json file"
    type = string
    default = ""
}

variable "node_secret_name" {
    description = "key"
    type = string
}

variable besu_image {
    description = "Image Docker do Besu"
    type = string
    default = "hyperledger/besu:25.5.0"
}

variable "storage_size" {
    description = "Tamanho do PVC para chain data"
    type = string
    default = "5Gi"
}

variable "replicas" {
    description = "Numero de replicas do sttefulset (deixei padrao 1)"
    type = number
    default = 1
}

/*
variable "genesis_json_path" {
    description = " Genesis.json path"
    type = string
}

variable "node_key_path" {
    description = "node key path"
    type = string
}*/

