resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  spec {
    ingress_class_name = "cilium"

    tls {
      hosts       = ["grafana.pandora"]
      secret_name = "grafana-tls"
    }

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

  depends_on = [helm_release.cilium, helm_release.grafana, helm_release.pandora_tls]
}

resource "kubernetes_ingress_v1" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  spec {
    ingress_class_name = "cilium"

    tls {
      hosts       = ["prometheus.pandora"]
      secret_name = "prometheus-tls"
    }

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

  depends_on = [helm_release.cilium, helm_release.prometheus, helm_release.pandora_tls]
}

resource "kubernetes_ingress_v1" "hubble" {
  metadata {
    name      = "hubble"
    namespace = "kube-system"
  }

  spec {
    ingress_class_name = "cilium"

    tls {
      hosts       = ["hubble.pandora"]
      secret_name = "hubble-tls"
    }

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

  depends_on = [helm_release.cilium, helm_release.pandora_tls]
}
