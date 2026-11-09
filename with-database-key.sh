#!/usr/bin/env bash
#
# with-database-key.sh: run a command with DATABASE_KEY (the db_backend API key)
# fetched from Bitwarden Secrets Manager.
#
# Usage: with-database-key.sh <command> [args...]
#
# Reads the BWS "common" project and passes only DATABASE_KEY to the command.
# Nothing is written to disk, and the BWS token is not passed on. If BWS is
# unreachable the run fails (non-zero exit), and the next scheduled run retries.
#
# Overrides (for tests and other hosts): BWS_BIN, BWS_TOKEN_FILE, BWS_COMMON_PROJECT.
set -euo pipefail

BWS="${BWS_BIN:-/usr/local/bin/bws}"
TOKEN_FILE="${BWS_TOKEN_FILE:-/etc/hydra/bws.env}"
COMMON_PROJECT="${BWS_COMMON_PROJECT:-d7153c8d-b8b6-4a59-a514-b47f00551367}" # common

log() { printf 'with-database-key: %s\n' "$*" >&2; }

if [[ $# -lt 1 ]]; then
    log "usage: with-database-key.sh <command> [args...]"
    exit 2
fi

if [[ -z "${BWS_ACCESS_TOKEN:-}" ]]; then
    if [[ ! -r "$TOKEN_FILE" ]]; then
        log "BWS_ACCESS_TOKEN not set and $TOKEN_FILE not readable"
        exit 1
    fi
    # shellcheck disable=SC1090
    . "$TOKEN_FILE"
fi

if ! secrets="$(BWS_ACCESS_TOKEN="$BWS_ACCESS_TOKEN" "$BWS" secret list "$COMMON_PROJECT" --output env 2>/dev/null)"; then
    log "bws fetch of the common project failed"
    exit 1
fi

# bws prints KEY="value" lines (quotes optional); keep only DATABASE_KEY.
DATABASE_KEY="$(printf '%s\n' "$secrets" | sed -n 's/^DATABASE_KEY=//p' | head -n 1)"
DATABASE_KEY="${DATABASE_KEY#\"}"
DATABASE_KEY="${DATABASE_KEY%\"}"
unset secrets BWS_ACCESS_TOKEN

if [[ -z "$DATABASE_KEY" ]]; then
    log "DATABASE_KEY not found in the common project"
    exit 1
fi

export DATABASE_KEY
exec "$@"
