#!/usr/bin/env bash

set -euo pipefail

readonly REMOTE_HOST="${REMOTE_HOST:-mac-mini}"
readonly REMOTE_REPO="${REMOTE_REPO:-~/Projects/pandora}"
readonly PROFILE="${COLIMA_PROFILE:-default}"
readonly K8S_PORT="${K8S_PORT:-6443}"
readonly OUTPUT="${KUBECONFIG:-$HOME/.kube/mac-mini-k3s.yaml}"
readonly CONTEXT="mac-mini-k3s"

case "$PROFILE" in
*[!A-Za-z0-9._-]* | '')
	printf 'invalid COLIMA_PROFILE: %s\n' "$PROFILE" >&2
	exit 1
	;;
esac

case "$K8S_PORT" in
*[!0-9]* | '')
	printf 'K8S_PORT must be numeric: %s\n' "$K8S_PORT" >&2
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
command -v jq >/dev/null 2>&1 || {
	printf 'required command not found: jq\n' >&2
	exit 1
}

mkdir -p "$(dirname -- "$OUTPUT")"
umask 077
temp_file="$(mktemp "${TMPDIR:-/tmp}/pandora-kubeconfig.XXXXXX")"
trap 'rm -f "$temp_file"' EXIT

case "$REMOTE_REPO" in
\~/*) remote_repo_arg="\$HOME/${REMOTE_REPO#\~/}" ;;
\$HOME/*) remote_repo_arg="$REMOTE_REPO" ;;
*) printf -v remote_repo_arg '%q' "$REMOTE_REPO" ;;
esac
printf -v profile_arg '%q' "$PROFILE"

remote_command="cd $remote_repo_arg && ./scripts/with-tools.sh colima list --profile $profile_arg --json"
# The command is intentionally assembled for evaluation by the remote shell.
# shellcheck disable=SC2029
colima_listing="$(ssh -o IgnoreUnknown=UseKeychain "$REMOTE_HOST" "$remote_command")"
server_address="$(printf '%s\n' "$colima_listing" | jq -Rr 'fromjson? | .address // empty')"
case "$server_address" in
*[!0-9.]* | '')
	printf 'could not determine a LAN address for Colima profile %s\n' "$PROFILE" >&2
	printf 'ensure Colima uses network.address=true and is running\n' >&2
	exit 1
	;;
esac

ssh_command="cd $remote_repo_arg && ./scripts/with-tools.sh colima ssh --profile $profile_arg -- sudo cat /etc/rancher/k3s/k3s.yaml"
# The command is intentionally assembled for evaluation by the remote shell.
# shellcheck disable=SC2029
ssh -o IgnoreUnknown=UseKeychain "$REMOTE_HOST" "$ssh_command" >"$temp_file"

sed \
	-e "s#^[[:space:]]*server:.*#    server: https://${server_address}:${K8S_PORT}#" \
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
	printf 'kubectl could not reach the API; ensure Colima is running and reachable on the LAN\n' >&2
	exit 1
fi
