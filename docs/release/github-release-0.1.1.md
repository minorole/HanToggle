# HanToggle 0.1.1

HanToggle 0.1.1 is a privacy-hardening rebuild of the macOS menu-bar utility for toggling selected Chinese text between Simplified and Traditional.

## Download

Download `HanToggle-0.1.1.dmg`, open it, and drag `HanToggle.app` to Applications.

## What Changed

- Removed developer-local source and build paths from the release binary.
- Removed internal agent instructions, work journals, planning documents, and source artwork from the public repository and website.
- Added publication checks that reject local-only files, personal paths, credential markers, and AI process attribution.

There are no functional conversion or hotkey changes in this release.

## Compatibility

- macOS 13 or newer
- Universal build for Apple Silicon and Intel Macs

## Privacy

HanToggle converts text locally. It does not include analytics, telemetry, crash reporting, update checks, or network conversion.

Selected text, converted text, and clipboard contents are not logged, persisted, or transmitted. The text replacement flow is designed to preserve the user's clipboard whenever possible.

## Support

For feedback, feature requests, or support, email hi@minor-role.com.

Do not include private selected text, clipboard contents, credentials, tokens, or personal data in support messages.

## Verification

The release is built for Apple Silicon and Intel, signed with Developer ID, notarized by Apple, stapled, Gatekeeper-checked, and scanned to reject absolute developer-home paths before publication.
