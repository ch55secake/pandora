# pandora

Pandora is a deliberately small Kubernetes networking lab running k3s in a
bridged Colima VM on a Mac mini. Cilium is installed and managed from the
laptop with Terraform. The Mac mini stores no Terraform state.

## Prerequisites

Install Nix with flakes enabled on the laptop when possible. Homebrew is the
supported fallback for hosts that do not have Nix, including the Mac mini.
The repository's flake remains the preferred source for project tooling.

Configure an SSH host named `mac-mini` for the Mac mini. The default remote
checkout is `~/Projects/pandora`; override it with `REMOTE_REPO` when necessary.

Enter the Nix development shell before running commands directly:

```sh
nix develop
```

The shell provides Colima, kubectl, Terraform, Helm, the Cilium CLI, SSH, and
the validation tools used by this repository. Make targets automatically use
the Nix shell when available and otherwise install the tracked `Brewfile`
dependencies through Homebrew.

To prepare a Homebrew-only machine manually:

```sh
brew bundle --file=Brewfile
```

## Workflows

### 1. Bootstrap the host

Clone or update this repository on the Mac mini, then run from the laptop:

```sh
make bootstrap
```

This starts the configured Colima profile and verifies that k3s is running.
It does not run Terraform. If Nix is unavailable on the Mac mini, the target
uses Homebrew and the tracked `Brewfile` automatically.
The first bridged-network start may request the Mac mini user's `sudo` password,
so run `make bootstrap` from an interactive terminal.
The committed profile targets the Mac mini's active Wi-Fi interface, `en1`;
change `network.interface` for a different host interface.

### 2. Configure LAN access

Colima uses bridged networking and assigns the VM a LAN-reachable address. The
dedicated kubeconfig discovers that address over SSH and points directly to the
Kubernetes API:

```sh
make kubeconfig
export KUBECONFIG="$HOME/.kube/mac-mini-k3s.yaml"
kubectl get nodes
```

The generated kubeconfig is never merged into the default kubeconfig.
Keep port `6443` restricted to the trusted LAN; do not expose it through the
router or firewall to the internet.

### 3. Run Terraform

With `KUBECONFIG` set:

```sh
make tf-init
make plan
make apply
```

Terraform installs Cilium, enables the initial Hubble components, and creates
the namespace used by the test workload.

### 4. Verify the cluster

Run the complete base-cluster verification:

```sh
make verify
```

This checks the node, system pods, Cilium, Hubble, workload readiness, service
routing, DNS, and the Cilium connectivity test.

After the baseline is healthy, apply the optional policy experiment:

```sh
kubectl apply -f kubernetes/test-app/network-policy.yaml
hubble observe -P --namespace pandora-test --last 20
```

The policy allows HTTP traffic from labeled test clients and denies other
ingress to the test workload. Remove it with `kubectl delete -f` when the
experiment is complete.

## Milestone 1: Base Cluster

- [ ] Repository created
- [ ] Nix development shell is reproducible
- [ ] Colima config committed
- [ ] Colima starts on the Mac mini
- [ ] k3s starts without Flannel
- [ ] Laptop reaches the Kubernetes API
- [ ] kubectl works from the laptop
- [ ] Terraform initializes
- [ ] Terraform installs Cilium
- [ ] Cilium reports healthy
- [ ] Hubble works
- [ ] Test workload has connectivity
- [ ] Cilium connectivity test passes

## Layout

See [`docs/architecture.md`](docs/architecture.md) for the deployment model
and [`docs/bootstrap.md`](docs/bootstrap.md) for host setup and recovery
details.

The next phases are kube-proxy replacement and eBPF experiments, LAN ingress,
persistent storage and backups, GitOps, and monitoring.
