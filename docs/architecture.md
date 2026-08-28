# Architecture

Pandora keeps the control plane private to the Mac mini and exposes the
Kubernetes API to the laptop only through an SSH local forward.

```text
+--------+      SSH       +---------+       Colima VM       +-----+
| Laptop | -------------- | Mac mini| --------------------> | k3s |
+--------+  local :6443   +---------+                       +--+--+
      |                         |                              |
      | kubectl/Terraform       | host process                | CNI
      |                         |                              v
      +-------------------------+-------------------------- Cilium
                                                               |
                                                     Hubble Relay/UI
```

## Responsibilities

- The laptop runs Nix, kubectl, the Cilium CLI, Terraform, and Helm tooling.
- The Mac mini runs Colima and the single-node k3s cluster.
- Terraform runs only on the laptop.
- Terraform state stays on the laptop and is excluded from Git.
- The Mac mini does not need a LAN-exposed Kubernetes API.
- The SSH tunnel maps laptop `127.0.0.1:6443` to Mac mini
  `127.0.0.1:6443`.
- Cilium replaces the disabled Flannel CNI.
- Hubble provides the first network-flow observability experiment.

## Initial boundaries

The first milestone intentionally excludes ingress, certificates, GitOps,
monitoring, storage, and application services beyond the test workload.
