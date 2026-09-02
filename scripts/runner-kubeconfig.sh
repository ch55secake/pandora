#!/usr/bin/env bash

set -euo pipefail

readonly PROFILE="${COLIMA_PROFILE:-default}"
readonly K8S_PORT="${K8S_PORT:-6443}"
readonly OUTPUT="${KUBECONFIG:?KUBECONFIG must point to the runner kubeconfig}"

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

for command_name in colima kubectl; do
	if ! command -v "$command_name" >/dev/null 2>&1; then
		printf 'required command not found: %s\n' "$command_name" >&2
		exit 1
	fi
done

mkdir -p "$(dirname -- "$OUTPUT")"
umask 077
temp_file="$(mktemp "${TMPDIR:-/tmp}/pandora-runner-kubeconfig.XXXXXX")"
trap 'rm -f "$temp_file"' EXIT

colima ssh --profile "$PROFILE" -- sudo cat /etc/rancher/k3s/k3s.yaml >"$temp_file"
sed -i '' \
	-e "s#^[[:space:]]*server:.*#    server: https://127.0.0.1:${K8S_PORT}#" \
	"$temp_file"
mv -- "$temp_file" "$OUTPUT"
chmod 600 "$OUTPUT"

KUBECONFIG="$OUTPUT" kubectl get nodes
