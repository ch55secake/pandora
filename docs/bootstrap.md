# Bootstrap

## Laptop prerequisites

- Nix with flakes enabled, or Homebrew
- An SSH config entry named `mac-mini`
- A checkout of this repository on the laptop

## Mac mini prerequisites

- macOS with hardware virtualization available
- Nix with flakes enabled, or Homebrew
- An SSH-accessible checkout at `~/Projects/pandora`

The repository's Nix development shell supplies all project commands. When Nix
is unavailable, `scripts/with-tools.sh` installs and uses the tracked
`Brewfile` instead.

## First bootstrap

From the laptop:

```sh
make bootstrap
```

The target invokes `host/start-colima.sh` through the repository tool wrapper on
the Mac mini. The wrapper prefers Nix and falls back to Homebrew. The script
installs the committed Colima profile configuration, starts Colima when needed,
and waits for the k3s API. The first bridged-network start may request the Mac
mini user's `sudo` password; `make bootstrap` allocates a terminal for it.
The committed profile uses the Mac mini's active Wi-Fi interface, `en1`; change
`network.interface` in `host/colima.yaml` if the host uses another interface.
The ingress configuration also disables k3s' bundled kube-proxy for Cilium's
kube-proxy replacement. Terraform derives Cilium's Kubernetes API host from the
node's LAN `InternalIP`, because the Kubernetes service IP is not reachable
until Cilium is running. Stop and start an existing Colima profile after this
configuration changes:

```sh
ssh mac-mini 'cd ~/Projects/pandora && ./scripts/with-tools.sh colima stop'
make bootstrap
```

If the host is not reachable, check the SSH alias first:

```sh
ssh mac-mini 'uname -a'
```

If neither Nix nor Homebrew is available on the host, install one before
retrying. Homebrew-only hosts do not need flakes enabled.

## Recovery

The bootstrap script is safe to run repeatedly. Configuration changes to an
already-running Colima profile require an explicit restart. Do not reset the
cluster as part of normal troubleshooting; inspect the current state first:

```sh
ssh mac-mini 'cd ~/Projects/pandora && ./scripts/with-tools.sh colima status'
ssh mac-mini 'cd ~/Projects/pandora && ./scripts/with-tools.sh colima list'
```

If the API is unavailable from the laptop, confirm that Colima is running and
that the generated kubeconfig points to the VM's LAN address on port `6443`.

## Full teardown

Run the teardown from the laptop while Colima is running and reachable on the
LAN:

```sh
make teardown
```

After confirmation, the target destroys Terraform-managed resources, deletes
the remote Colima profile with its data, and removes the generated local
kubeconfig. The teardown aborts before deleting Colima if Terraform
destruction fails.
