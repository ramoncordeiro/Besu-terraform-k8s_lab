resource "kubernetes_service" "besu_node" {
  metadata {
    //name = "besu-validator"
    name = "besu-${var.node_name}"
    labels = {
      app       = "besu-${var.node_name}"
      besu-node = "true"
    }
  }

  spec {
    selector = {
      //app = "besu-validator"
      app = "besu-${var.node_name}"
    }
    port {
      name        = "p2p-tcp"
      protocol    = "TCP"
      port        = 30303
      target_port = 30303
    }
    port {
      name        = "p2p-udp"
      protocol    = "UDP"
      port        = 30303
      target_port = 30303
    }
    port {
      name        = "rpc"
      protocol    = "TCP"
      port        = 8545
      target_port = 8545
    }
    port {
      name        = "metrics"
      protocol    = "TCP"
      port        = 9545
      target_port = 9545
    }
    type = "ClusterIP"
  }
}

