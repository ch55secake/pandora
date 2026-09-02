# Architecture

Pandora runs the control plane in a bridged Colima VM and exposes the
Kubernetes API on the trusted LAN. The laptop connects directly to the VM's
LAN address; SSH is used for bootstrap and kubeconfig discovery. Terraform can
also run from a self-hosted GitHub Actions runner on the Mac mini.

```text
+--------+       LAN        +---------+     bridged      +-----+
| Laptop | ---------------- | Mac mini| --------------> | k3s |
+--------+  VM IP:6443     +---------+   Colima VM      +--+--+
      |                         |                         |
      | kubectl/Terraform       | SSH bootstrap           | CNI
      |                         |                         v
      +-------------------------+--------------------- Cilium
                                                          |
                                                Hubble Relay/UI
```

## Responsibilities

- The laptop runs Nix, kubectl, the Cilium CLI, Terraform, and Helm tooling for
  interactive administration.
- The Mac mini runs Colima and the single-node k3s cluster.
- Terraform runs interactively on the laptop or automatically on the Mac mini
  runner.
- Terraform state stays on the laptop for interactive use or at the Mac mini's
  persistent local state path for automation; it is excluded from Git.
- The Colima VM uses bridged networking and receives a LAN-reachable IPv4
  address.
- The Kubernetes API is available at the VM's LAN address on port `6443`.
- Cilium Ingress publishes the selected HTTP services through fixed NodePorts at
  the VM's LAN address on ports `80` and `443`.
- Network controls must keep ports `80`, `443`, and `6443` on the trusted LAN
  and off the WAN.
- Cilium provides the kube-proxy replacement required by its ingress
  controller; k3s' bundled kube-proxy is disabled.
- Cilium replaces the disabled Flannel CNI.
- Hubble provides the first network-flow observability experiment.

## Initial boundaries

The first milestone intentionally excludes GitOps, storage, and application
services beyond the test workload. TLS uses a private cert-manager CA for the
LAN-only service names.
