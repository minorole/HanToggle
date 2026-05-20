# Contributing

Thanks for helping improve HanToggle. The project aims to stay small, local-first, and reliable.

## Development

Install Xcode or the Apple Swift toolchain, then run commands from the repository root.

```sh
swift build
swift test
swift run hantoggle "这句话是简体中文。"
swift run hantoggle "這句話是簡體中文。"
swift run HanToggleApp
```

To create a local release app bundle for manual testing:

```sh
Scripts/build-app.sh
```

## Privacy Rules

- Treat selected text and clipboard contents as private user data.
- Do not log selected text, clipboard contents, converted text, credentials, or personal data.
- Do not persist selected text or clipboard contents to disk.
- Do not transmit selected text or clipboard contents over the network.
- Preserve the user's clipboard whenever possible.

## Tests

Conversion behavior changes need focused tests in `Tests/HanToggleTests`. Keep coverage for Simplified to Traditional, Traditional to Simplified, repeat toggle, mixed text, and non-Chinese no-op behavior.

For app, hotkey, pasteboard, and settings behavior, add or update tests under `Tests/HanToggleAppTests` where practical.
