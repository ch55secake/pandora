resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = var.cert_manager_version

  atomic           = true
  cleanup_on_fail  = true
  create_namespace = true
  timeout          = 900
  wait             = true

  values = [yamlencode({
    crds = {
      enabled = true
      keep    = true
    }
  })]
}

resource "helm_release" "pandora_tls" {
  name      = "pandora-tls"
  chart     = "${path.module}/../helm/pandora-tls"
  namespace = "cert-manager"

  atomic                     = true
  cleanup_on_fail            = true
  create_namespace           = false
  disable_openapi_validation = true
  timeout                    = 900
  wait                       = true

  depends_on = [helm_release.cert_manager, kubernetes_namespace_v1.monitoring]
}
