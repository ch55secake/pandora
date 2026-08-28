output "cilium_release" {
  description = "Installed Cilium Helm release."
  value       = helm_release.cilium.name
}

output "cilium_version" {
  description = "Installed Cilium chart version."
  value       = helm_release.cilium.version
}

output "test_namespace" {
  description = "Namespace available for the test workload."
  value       = kubernetes_namespace_v1.test.metadata[0].name
}
