# Architecture

Pandora runs the control plane in a bridged Colima VM and exposes the
Kubernetes API on the trusted LAN. The laptop connects directly to the VM's
LAN address; SSH is used only for bootstrap and kubeconfig discovery.

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

- The laptop runs Nix, kubectl, the Cilium CLI, Terraform, and Helm tooling.
- The Mac mini runs Colima and the single-node k3s cluster.
- Terraform runs only on the laptop.
- Terraform state stays on the laptop and is excluded from Git.
- The Colima VM uses bridged networking and receives a LAN-reachable IPv4
  address.
- The Kubernetes API is available at the VM's LAN address on port `6443`.
- Network controls must keep port `6443` on the trusted LAN and off the WAN.
- Cilium replaces the disabled Flannel CNI.
- Hubble provides the first network-flow observability experiment.

## Initial boundaries

The first milestone intentionally excludes ingress, certificates, GitOps,
monitoring, storage, and application services beyond the test workload.
