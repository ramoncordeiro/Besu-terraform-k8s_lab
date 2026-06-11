output "service_name" {
  description = "Nodes"
  value       = "besu-${var.node_name}"
}

output "statefulset_name" {
  description = "Nome of StatefulSet"
  value       = "besu-${var.node_name}"
}

