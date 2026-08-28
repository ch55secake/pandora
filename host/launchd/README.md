# launchd

Launchd integration is intentionally deferred until the base cluster is
stable. The first milestone starts Colima explicitly through
`host/start-colima.sh`, which keeps failures visible during bootstrap.

When a launchd service is added, it should invoke the repository script inside
the Nix development environment, use the `mac-mini-k3s` profile explicitly,
and write logs outside the repository. It must not run Terraform.
