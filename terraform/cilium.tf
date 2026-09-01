data "kubernetes_nodes" "cluster" {}

locals {
  # kube-proxy is disabled, so Cilium's init containers must use the node's
  # reachable API address instead of the Kubernetes service IP.
  cilium_k8s_service_host = one(flatten([
    for node in data.kubernetes_nodes.cluster.nodes : [
      for address in node.status[0].addresses : address.address
      if address.type == "InternalIP" && !strcontains(address.address, ":")
    ]
  ]))
}

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
    kubeProxyReplacement = true
    k8sServiceHost       = local.cilium_k8s_service_host
    k8sServicePort       = 6443

    envoy = {
      securityContext = {
        capabilities = {
          envoy = [
            "NET_ADMIN",
            "SYS_ADMIN",
            "NET_BIND_SERVICE",
          ]
          keepCapNetBindService = true
        }
      }
    }

    ingressController = {
      enabled          = true
      enforceHttps     = true
      loadbalancerMode = "shared"

      hostNetwork = {
        enabled            = true
        sharedListenerPort = 80
        httpPort           = 80
        httpsPort          = 443
      }
    }

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
