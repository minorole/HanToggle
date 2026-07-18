# HanToggle 0.1.1 Release Verification

Date: 2026-07-18
Version: 0.1.1
Build: 2
Verification: Release checklist

## Automated checks

- `swift test`: 134 tests passed in 17 suites.
- CLI conversion was verified in both directions.
- The public-boundary guard passed for the source tree, signed app, and mounted DMG payload.
- The rewritten public history passed metadata, topology, tag, path, and content validation across 112 commits.

## Release artifact

- File: `HanToggle-0.1.1.dmg`
- SHA-256: `f20717a3622b9c6c12cef59fd6a27cba96d6d06e84b521c69053e64233b7b390`
- Size: 4,127,462 bytes
- Architectures: arm64 and x86_64
- App signature: valid
- App notarization ticket: stapled and validated
- DMG notarization ticket: stapled and validated
- Gatekeeper assessment: accepted as Notarized Developer ID
- Packaged-app smoke launch: passed

The release contains no functional conversion or hotkey changes from 0.1.0.
