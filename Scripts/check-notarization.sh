#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROFILE="${NOTARY_PROFILE:-notarization-profile}"

cd "$PROJECT_DIR"

echo "Checking Apple notarytool profile '$PROFILE'..."

if xcrun notarytool history --keychain-profile "$PROFILE"; then
    echo "Notary profile '$PROFILE' is available."
else
    echo "Notary profile '$PROFILE' check failed." >&2
    echo "Check that the keychain profile exists and can access Apple notarization." >&2
    exit 1
fi
