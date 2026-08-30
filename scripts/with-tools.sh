#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
readonly REPO_ROOT
readonly BREWFILE="$REPO_ROOT/Brewfile"

# Non-interactive SSH sessions do not usually load Homebrew's shell setup.
if ! command -v brew >/dev/null 2>&1; then
	for brew_bin in /opt/homebrew/bin /usr/local/bin; do
		if [[ -x "$brew_bin/brew" ]]; then
			PATH="$brew_bin:$PATH"
			export PATH
			break
		fi
	done
fi

if [[ "$#" -eq 0 ]]; then
	printf 'usage: %s command [argument ...]\n' "$0" >&2
	exit 2
fi

# Avoid nesting a development shell when called from `nix develop`.
if [[ -n "${IN_NIX_SHELL:-}" ]]; then
	exec "$@"
fi

if command -v nix >/dev/null 2>&1; then
	exec nix develop --command "$@"
fi

if ! command -v brew >/dev/null 2>&1; then
	printf 'neither Nix nor Homebrew is installed\n' >&2
	printf 'install Nix with flakes enabled or install Homebrew, then retry\n' >&2
	exit 1
fi

if ! brew bundle check --file="$BREWFILE" >/dev/null 2>&1; then
	printf 'installing Pandora Homebrew dependencies\n'
	brew bundle --file="$BREWFILE"
fi

exec "$@"
