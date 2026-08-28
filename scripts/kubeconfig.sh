#!/usr/bin/env bash

set -euo pipefail

readonly REMOTE_HOST="${REMOTE_HOST:-mac-mini}"
readonly REMOTE_REPO="${REMOTE_REPO:-~/pandora}"
readonly PROFILE="${COLIMA_PROFILE:-default}"
readonly LOCAL_PORT="${K8S_LOCAL_PORT:-6443}"
readonly OUTPUT="${KUBECONFIG:-$HOME/.kube/mac-mini-k3s.yaml}"
readonly CONTEXT="mac-mini-k3s"

case "$PROFILE" in
*[!A-Za-z0-9._-]* | '')
	printf 'invalid COLIMA_PROFILE: %s\n' "$PROFILE" >&2
	exit 1
	;;
esac

case "$LOCAL_PORT" in
*[!0-9]* | '')
	printf 'K8S_LOCAL_PORT must be numeric: %s\n' "$LOCAL_PORT" >&2
	exit 1
	;;
esac

command -v ssh >/dev/null 2>&1 || {
	printf 'required command not found: ssh\n' >&2
	exit 1
}
command -v kubectl >/dev/null 2>&1 || {
	printf 'required command not found: kubectl\n' >&2
	exit 1
}

mkdir -p "$(dirname -- "$OUTPUT")"
umask 077
temp_file="$(mktemp "${TMPDIR:-/tmp}/pandora-kubeconfig.XXXXXX")"
trap 'rm -f "$temp_file"' EXIT

printf -v remote_repo_arg '%q' "$REMOTE_REPO"
printf -v profile_arg '%q' "$PROFILE"
ssh_command="cd $remote_repo_arg && nix develop --command colima ssh --profile $profile_arg -- sudo cat /etc/rancher/k3s/k3s.yaml"
# The command is intentionally assembled for evaluation by the remote shell.
# shellcheck disable=SC2029
ssh "$REMOTE_HOST" "$ssh_command" >"$temp_file"

sed \
	-e "s#^[[:space:]]*server:.*#    server: https://127.0.0.1:${LOCAL_PORT}#" \
	-e "s/^[[:space:]]*current-context:.*/current-context: ${CONTEXT}/" \
	-e "s/default/${CONTEXT}/g" \
	"$temp_file" >"$OUTPUT"

chmod 600 "$OUTPUT"
printf 'wrote dedicated kubeconfig: %s\n' "$OUTPUT"

if ! KUBECONFIG="$OUTPUT" kubectl config get-contexts "$CONTEXT" >/dev/null 2>&1; then
	printf 'generated kubeconfig does not contain context %s\n' "$CONTEXT" >&2
	exit 1
fi

if ! KUBECONFIG="$OUTPUT" kubectl get nodes; then
	printf 'kubectl could not reach the API; ensure make tunnel is running\n' >&2
	exit 1
fi
