#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
readonly REPO_ROOT
readonly TERRAFORM_DIR="$REPO_ROOT/terraform"
readonly REMOTE_HOST="${REMOTE_HOST:-mac-mini}"
readonly REMOTE_REPO="${REMOTE_REPO:-~/Projects/pandora}"
readonly PROFILE="${COLIMA_PROFILE:-default}"
readonly KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/mac-mini-k3s.yaml}"

usage() {
	cat <<'EOF'
Usage: teardown.sh [--yes]

Destroy Terraform-managed resources, delete the remote Colima profile and its
data, and remove the generated local kubeconfig.

Use --yes to skip the confirmation prompt.
EOF
}

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		printf 'required command not found: %s\n' "$1" >&2
		exit 1
	fi
}

confirm=false
while [[ "$#" -gt 0 ]]; do
	case "$1" in
	--yes | -y)
		confirm=true
		;;
	--help | -h)
		usage
		exit 0
		;;
	*)
		printf 'unknown option: %s\n' "$1" >&2
		usage >&2
		exit 2
		;;
	esac
	shift
done

case "$PROFILE" in
*[!A-Za-z0-9._-]* | '')
	printf 'invalid COLIMA_PROFILE: %s\n' "$PROFILE" >&2
	exit 1
	;;
esac

require_command terraform
require_command ssh

if [[ ! -f "$KUBECONFIG_PATH" ]]; then
	printf 'kubeconfig not found: %s\n' "$KUBECONFIG_PATH" >&2
	printf 'run make kubeconfig while Colima is reachable on the LAN, then retry\n' >&2
	exit 1
fi

if [[ -d "$KUBECONFIG_PATH" && ! -L "$KUBECONFIG_PATH" ]]; then
	printf 'kubeconfig path is a directory: %s\n' "$KUBECONFIG_PATH" >&2
	exit 1
fi

if [[ "$confirm" != true ]]; then
	cat <<EOF
This permanently tears down Pandora:
- Terraform-managed Kubernetes resources
- The remote Colima profile '$PROFILE' and all its data
- The local kubeconfig '$KUBECONFIG_PATH'

The Kubernetes API must remain reachable on the LAN until Terraform destruction finishes.
EOF
	printf "Type 'destroy' to continue: "
	IFS= read -r confirmation || {
		printf '\nteardown aborted\n' >&2
		exit 1
	}
	if [[ "$confirmation" != destroy ]]; then
		printf 'teardown aborted\n' >&2
		exit 1
	fi
fi

printf '%s\n' 'destroying Terraform-managed resources'
terraform -chdir="$TERRAFORM_DIR" init -input=false -lockfile=readonly
terraform -chdir="$TERRAFORM_DIR" destroy \
	-auto-approve \
	-input=false \
	-var="kubeconfig_path=$KUBECONFIG_PATH"

case "$REMOTE_REPO" in
"~/"*) remote_repo_arg="\$HOME/${REMOTE_REPO#\~/}" ;;
"\$HOME/"*) remote_repo_arg="$REMOTE_REPO" ;;
*) printf -v remote_repo_arg '%q' "$REMOTE_REPO" ;;
esac
printf -v profile_arg '%q' "$PROFILE"
remote_command="cd $remote_repo_arg && ./scripts/with-tools.sh colima delete --profile $profile_arg --data --force"
# The command is intentionally assembled for evaluation by the remote shell.
# shellcheck disable=SC2029
ssh -o BatchMode=yes -o IgnoreUnknown=UseKeychain "$REMOTE_HOST" "$remote_command"

rm -f -- "$KUBECONFIG_PATH"
printf 'removed local kubeconfig: %s\n' "$KUBECONFIG_PATH"
printf '%s\n' 'Pandora teardown complete'
