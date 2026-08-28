# Bootstrap

## Laptop prerequisites

- Nix with flakes enabled
- An SSH config entry named `mac-mini`
- A checkout of this repository on the laptop

## Mac mini prerequisites

- macOS with hardware virtualization available
- Nix with flakes enabled
- An SSH-accessible checkout at `~/pandora`

The repository's Nix development shell supplies all project commands. No
Homebrew installation or system-wide Terraform setup is required.

## First bootstrap

From the laptop:

```sh
make bootstrap
```

The target invokes `host/start-colima.sh` inside the repository's Nix shell on
the Mac mini. The script installs the committed Colima profile configuration,
starts Colima when needed, and waits for the k3s API.

If the host is not reachable, check the SSH alias first:

```sh
ssh mac-mini 'uname -a'
```

If Nix is unavailable on the host, install and enable flakes before retrying.

## Recovery

The bootstrap script is safe to run repeatedly. Configuration changes to an
already-running Colima profile require an explicit restart. Do not reset the
cluster as part of normal troubleshooting; inspect the current state first:

```sh
ssh mac-mini 'cd ~/pandora && nix develop --command colima status'
ssh mac-mini 'cd ~/pandora && nix develop --command colima kubernetes status'
```

If the API is unavailable from the laptop, confirm that the tunnel is running
and that the generated kubeconfig points to `https://127.0.0.1:6443`.
