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

The Hubble UI is also available directly on the VM LAN address at
`http://<colima-lan-address>:31235` through its fixed NodePort.

Cilium ingress exposes the monitoring services on port `80`. Create these
individual records in the router's LAN DNS configuration:

```text
grafana.pandora     -> <colima-lan-address>
prometheus.pandora  -> <colima-lan-address>
hubble.pandora      -> <colima-lan-address>
```

After ingress is enabled, use `http://grafana.pandora`,
`http://prometheus.pandora`, and `http://hubble.pandora`. Keep port `80`
restricted to the trusted LAN; Prometheus and Hubble do not provide
authentication by default. Enabling ingress also enables Cilium's kube-proxy
replacement; stop and start an existing Colima profile before rerunning
`make bootstrap` so the new k3s argument takes effect.

### 3. Run Terraform

With `KUBECONFIG` set:

```sh
export TF_VAR_grafana_admin_password='use-a-password-manager-value'
make tf-init
make plan
make apply
```

Terraform installs Cilium, enables Hubble metrics and dashboards, deploys the
internal Prometheus and Grafana services, and creates the namespaces used by
the monitoring and test workloads. With kube-proxy disabled, Terraform also
passes Cilium the node's LAN `InternalIP` for API bootstrap. Keep the Grafana
password out of Git; the Terraform state remains local and is excluded from
Git.

### 4. Deploy Terraform from GitHub

The repository includes a deployment workflow for a self-hosted GitHub Actions
runner on the Mac mini. The runner must use the same macOS user that owns
Colima, have the custom `pandora` runner label, and keep Colima running. Install
the runner from the repository's GitHub Settings under Actions > Runners,
select macOS/ARM64, and install it as a service for that user. Add a repository
secret named `PANDORA_GRAFANA_ADMIN_PASSWORD` before enabling the workflow.

Before the first automated deployment, migrate the current local state from the
laptop to the Mac mini while no Terraform command is running:

```sh
make migrate-state
```

The state is stored at `~/.local/state/pandora/terraform.tfstate` on the Mac
mini. Merges to `main` that change Terraform configuration run a serialized
plan and apply on that runner. The workflow can also be retried with the
`workflow_dispatch` trigger. It fails rather than starting from empty state.

### 5. Verify the cluster

Run the complete base-cluster verification:

```sh
make verify
```

This checks the node, system pods, Cilium, Hubble, workload readiness, service
routing, DNS, and the single-node Cilium connectivity test.

Automated Terraform deployments use the same checks in smoke mode and skip the
full connectivity suite to keep deployments short. Run `make verify` when the
comprehensive Cilium policy and connectivity test is needed.

After the baseline is healthy, apply the optional policy experiment:

```sh
kubectl apply -f kubernetes/test-app/network-policy.yaml
hubble observe -P --namespace pandora-test --last 20
```

The policy allows HTTP traffic from labeled test clients and denies other
ingress to the test workload. Remove it with `kubectl delete -f` when the
experiment is complete.

### 6. Tear down Pandora

The full teardown requires Colima to remain reachable on the LAN while Terraform
destroys the Kubernetes resources:

```sh
make teardown
```

After Terraform completes, the target deletes the remote Colima profile and all
its data, then removes the generated local kubeconfig. Use
`./scripts/with-tools.sh ./scripts/teardown.sh --yes` instead of
`make teardown` when an explicit confirmation prompt is not suitable.

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

The next phases are eBPF experiments, TLS, Terraform deployment automation, and
monitoring.
