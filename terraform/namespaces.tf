resource "kubernetes_namespace_v1" "test" {
  metadata {
    name = var.test_namespace
  }
}

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}
