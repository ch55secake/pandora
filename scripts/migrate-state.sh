#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
readonly REPO_ROOT
readonly STATE_SOURCE="${TF_STATE_SOURCE:-$REPO_ROOT/terraform/terraform.tfstate}"
readonly REMOTE_HOST="${REMOTE_HOST:-mac-mini}"
readonly REMOTE_STATE_FILE=".local/state/pandora/terraform.tfstate"

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		printf 'required command not found: %s\n' "$1" >&2
		exit 1
	fi
}

require_command scp
require_command ssh

if [[ ! -s "$STATE_SOURCE" ]]; then
	printf 'Terraform state not found or empty: %s\n' "$STATE_SOURCE" >&2
	exit 1
fi

ssh -o BatchMode=yes -o IgnoreUnknown=UseKeychain "$REMOTE_HOST" \
	'test ! -e "$HOME/.local/state/pandora/terraform.tfstate" || {
		printf "remote Terraform state already exists; refusing to overwrite\n" >&2
		exit 1
	}; mkdir -p "$HOME/.local/state/pandora"; chmod 700 "$HOME/.local/state/pandora"'

scp -p -o BatchMode=yes -o IgnoreUnknown=UseKeychain \
	"$STATE_SOURCE" "$REMOTE_HOST:$REMOTE_STATE_FILE"
ssh -o BatchMode=yes -o IgnoreUnknown=UseKeychain "$REMOTE_HOST" \
	'chmod 600 "$HOME/.local/state/pandora/terraform.tfstate"'

printf 'migrated Terraform state to %s:%s\n' "$REMOTE_HOST" "$REMOTE_STATE_FILE"
