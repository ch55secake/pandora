variable "kubeconfig_path" {
  description = "Path to the dedicated Pandora kubeconfig on the laptop."
  type        = string
  default     = "~/.kube/mac-mini-k3s.yaml"
}

variable "cilium_version" {
  description = "Cilium Helm chart version."
  type        = string
  default     = "1.20.1"
}

variable "pod_cidr" {
  description = "Cilium cluster-pool CIDR matching k3s' default pod network."
  type        = string
  default     = "10.42.0.0/16"
}

variable "test_namespace" {
  description = "Namespace used by the intentionally simple test workload."
  type        = string
  default     = "pandora-test"
}
