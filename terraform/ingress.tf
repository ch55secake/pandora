resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  spec {
    ingress_class_name = "cilium"

    rule {
      host = "grafana.pandora"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = helm_release.grafana.name

              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.cilium, helm_release.grafana]
}

resource "kubernetes_ingress_v1" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  spec {
    ingress_class_name = "cilium"

    rule {
      host = "prometheus.pandora"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "${helm_release.prometheus.name}-server"

              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.cilium, helm_release.prometheus]
}

resource "kubernetes_ingress_v1" "hubble" {
  metadata {
    name      = "hubble"
    namespace = "kube-system"
  }

  spec {
    ingress_class_name = "cilium"

    rule {
      host = "hubble.pandora"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "hubble-ui"

              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.cilium]
}
