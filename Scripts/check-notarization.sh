#!/usr/bin/env bash
set -euo pipefail

PROFILE="${NOTARY_PROFILE:-notarization-profile}"

if xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
    echo "Notary profile '$PROFILE' is usable."
    exit 0
else
    echo "Notary profile '$PROFILE' is not usable." >&2
    echo "Run this command for details:" >&2
    echo "  xcrun notarytool history --keychain-profile $PROFILE" >&2
    exit 1
fi
