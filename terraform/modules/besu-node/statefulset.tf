locals {
  resource_name = "besu-${var.node_name}"

  base_args = [
    "--genesis-file=/etc/besu/genesis.json",
    "--node-private-key-file=/secrets/key",
    "--data-path=/var/lib/besu",
    "--rpc-http-enabled",
    "--rpc-http-host=0.0.0.0",
    "--host-allowlist=*",
    "--metrics-enabled",
    "--metrics-host=0.0.0.0",
    "--rpc-http-api=ETH,NET,QBFT,ADMIN,WEB3",
    "--min-gas-price=0",
    "--Xdns-enabled=true", #both flags help me to apply dns to nodes for Besu
    "--Xdns-update-enabled=true"
  ]

  static_nodes_args = var.static_nodes_configmap_name != "" ? ["--static-nodes-file=/etc/besu/static-nodes.json"] : []

  besu_args = concat(local.base_args, local.static_nodes_args)
}

resource "kubernetes_stateful_set" "besu_node" {
  metadata {
    name = local.resource_name
    labels = {
      app = local.resource_name
    }
  }

  spec {
    service_name = local.resource_name
    replicas     = var.replicas

    selector {
      match_labels = {
        app = local.resource_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.resource_name
        }
      }

      spec {
        container {
          name  = "app"
          image = var.besu_image

          #need to put more ports here
          port {
            container_port = 30303
            name           = "p2p-tcp"
          }
          port {
            container_port = 30303
            name           = "p2p-udp"
            protocol       = "UDP"
          }

          port {
            container_port = 8545
            name           = "rpc"
          }
          port {
            container_port = 9545
            name           = "metrics"
          }

          args = local.besu_args

          volume_mount {
            name       = "genesis"
            mount_path = "/etc/besu"
          }

          volume_mount {
            name       = "nodekey" #change
            mount_path = "/secrets"
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/besu"
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          readiness_probe {
            http_get {
              path = "/liveness"
              port = 8545
            }
            initial_delay_seconds = 30
            period_seconds        = 30
          }


        }


        #volumes that are not PVC (configMap, secret, emptyDir)
        volume {
          name = "genesis"
          config_map {
            name = var.genesis_configmap_name
          }
        }

        volume {
          name = "nodekey" # change
          secret {
            secret_name = var.node_secret_name
          }
        }


      }
    }


    ### Dinamyc PVC per POD (volumeCLaimTemplate in YAML)
    volume_claim_template {
      metadata {
        name = "data" #
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = var.storage_size
          }
        }
      }
    }
  }
}