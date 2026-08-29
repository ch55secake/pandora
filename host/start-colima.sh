#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly CONFIG_SOURCE="$SCRIPT_DIR/colima.yaml"
readonly PROFILE="${COLIMA_PROFILE:-default}"
readonly COLIMA_HOME_DIR="${COLIMA_HOME:-$HOME/.colima}"
readonly CONFIG_TARGET="$COLIMA_HOME_DIR/$PROFILE/colima.yaml"

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		printf 'required command not found: %s\n' "$1" >&2
		printf 'run this script through: ./scripts/with-tools.sh ./host/start-colima.sh\n' >&2
		exit 1
	fi
}

case "$PROFILE" in
*[!A-Za-z0-9._-]* | '')
	printf 'invalid COLIMA_PROFILE: %s\n' "$PROFILE" >&2
	exit 1
	;;
esac

require_command colima
require_command kubectl

if [[ ! -f "$CONFIG_SOURCE" ]]; then
	printf 'Colima configuration not found: %s\n' "$CONFIG_SOURCE" >&2
	exit 1
fi

mkdir -p "$(dirname -- "$CONFIG_TARGET")"
if [[ ! -f "$CONFIG_TARGET" ]] || ! cmp -s "$CONFIG_SOURCE" "$CONFIG_TARGET"; then
	cp "$CONFIG_SOURCE" "$CONFIG_TARGET"
	chmod 600 "$CONFIG_TARGET"
	printf 'installed Colima configuration for profile %s\n' "$PROFILE"
fi

colima start --profile "$PROFILE"

printf 'waiting for the k3s API on Colima profile %s\n' "$PROFILE"
for attempt in {1..60}; do
	if colima ssh --profile "$PROFILE" -- sudo k3s kubectl \
		--kubeconfig /etc/rancher/k3s/k3s.yaml get --raw=/readyz \
		>/dev/null 2>&1; then
		printf 'k3s API is ready\n'
		exit 0
	fi
	sleep 2
done

printf 'k3s API did not become ready within 120 seconds after %d attempts\n' "$attempt" >&2
colima status --profile "$PROFILE" >&2 || true
exit 1
