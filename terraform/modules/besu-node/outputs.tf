output "service_name" {
  description = "Nodes"
  //value = kubernetes_service.besu_node.metadata[0].name
  value = "besu-${var.node_name}"
}

output "statefulset_name" {
  description = "Nome of StatefulSet"
  //value = kubernetes_stateful_set.besu_node.metadata[0].name
  value = "besu-${var.node_name}"
}

