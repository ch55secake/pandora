resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  namespace  = "kube-system"
  version    = var.cilium_version

  atomic           = true
  cleanup_on_fail  = true
  create_namespace = false
  timeout          = 900
  wait             = true

  values = [yamlencode({
    kubeProxyReplacement = false

    prometheus = {
      enabled        = true
      metricsService = true
    }

    ipam = {
      mode = "cluster-pool"

      operator = {
        clusterPoolIPv4MaskSize    = 24
        clusterPoolIPv4PodCIDRList = [var.pod_cidr]
      }
    }

    operator = {
      replicas = 1

      prometheus = {
        enabled        = true
        metricsService = true
      }

      dashboards = {
        enabled = true
      }
    }

    hubble = {
      enabled = true

      metrics = {
        enabled = [
          "dns",
          "drop",
          "tcp",
          "flow",
          "icmp",
          "http",
          "port-distribution",
        ]

        dashboards = {
          enabled = true
        }
      }

      relay = {
        enabled = true
      }

      ui = {
        enabled = true

        service = {
          type     = "NodePort"
          nodePort = 31235
        }
      }
    }

    dashboards = {
      enabled = true
    }
  })]
}
