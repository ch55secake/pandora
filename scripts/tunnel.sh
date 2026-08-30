#!/usr/bin/env bash

set -euo pipefail

readonly REMOTE_HOST="${REMOTE_HOST:-mac-mini}"
readonly LOCAL_PORT="${K8S_LOCAL_PORT:-6443}"
readonly REMOTE_PORT="${K8S_REMOTE_PORT:-6443}"

case "$LOCAL_PORT:$REMOTE_PORT" in
*[!0-9:]* | :*)
	printf 'Kubernetes ports must be numeric: %s:%s\n' "$LOCAL_PORT" "$REMOTE_PORT" >&2
	exit 1
	;;
esac

printf 'forwarding 127.0.0.1:%s -> %s:127.0.0.1:%s\n' \
	"$LOCAL_PORT" "$REMOTE_HOST" "$REMOTE_PORT"
printf 'leave this process running while using kubectl or Terraform\n'

exec ssh \
	-o BatchMode=yes \
	-o ExitOnForwardFailure=yes \
	-o IgnoreUnknown=UseKeychain \
	-o ServerAliveInterval=30 \
	-o ServerAliveCountMax=3 \
	-N \
	-L "${LOCAL_PORT}:127.0.0.1:${REMOTE_PORT}" \
	"$REMOTE_HOST"
