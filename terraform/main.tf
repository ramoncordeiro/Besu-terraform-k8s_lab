resource "kubernetes_config_map" "besu_genesis_config" {
  metadata {
    name = "besu-genesis-config"
  }
  ## I could have defined two config_maps. Each per file. 
  data = {
    "genesis.json"      = file(var.genesis_json_path)
    "static-nodes.json" = file(var.static_nodes_json_path)
  }
}

resource "kubernetes_secret" "besu_node_key" {
  for_each = var.nodes

  metadata {
    name = "besu-${each.value.name}-key"
  }

  data = {
    "key" = file("../start-network/.env.configs/nodes/${each.value.name}/key")
  }
}

module "besu_node" {
  source   = "./modules/besu-node"
  for_each = var.nodes

  node_name                   = each.value.name
  node_type                   = each.value.type
  genesis_configmap_name      = kubernetes_config_map.besu_genesis_config.metadata[0].name
  static_nodes_configmap_name = kubernetes_config_map.besu_genesis_config.metadata[0].name
  node_secret_name            = kubernetes_secret.besu_node_key[each.key].metadata[0].name
}


#module "besu_node" {
#  source = "./modules/besu-node"

#  genesis_json_path = var.genesis_json_path
#  node_key_path     = var.node_key_path
#}