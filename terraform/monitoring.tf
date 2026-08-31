resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = var.prometheus_chart_version

  atomic           = true
  cleanup_on_fail  = true
  create_namespace = false
  timeout          = 900
  wait             = true

  values = [yamlencode({
    alertmanager = {
      enabled = false
    }

    "prometheus-pushgateway" = {
      enabled = false
    }

    server = {
      persistentVolume = {
        enabled = true
        size    = "8Gi"
      }

      service = {
        type = "ClusterIP"
      }
    }
  })]

  depends_on = [helm_release.cilium]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana-community.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = var.grafana_chart_version

  atomic           = true
  cleanup_on_fail  = true
  create_namespace = false
  timeout          = 900
  wait             = true

  set_sensitive = [{
    name  = "adminPassword"
    value = var.grafana_admin_password
  }]

  values = [yamlencode({
    persistence = {
      enabled = true
      size    = "2Gi"
    }

    service = {
      type = "ClusterIP"
    }

    datasources = {
      "datasources.yaml" = {
        apiVersion = 1
        datasources = [{
          name      = "Prometheus"
          type      = "prometheus"
          uid       = "prometheus"
          url       = "http://prometheus-server.monitoring.svc.cluster.local"
          access    = "proxy"
          isDefault = true
          editable  = false
        }]
      }
    }

    sidecar = {
      dashboards = {
        enabled         = true
        label           = "grafana_dashboard"
        labelValue      = "1"
        searchNamespace = "ALL"
      }
    }
  })]

  depends_on = [helm_release.prometheus]
}
