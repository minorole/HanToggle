# HanToggle

HanToggle is a lightweight macOS Chinese script toggler.

The goal is simple:

1. Select Chinese text anywhere on macOS.
2. Press one global hotkey.
3. Replace the selected text with the opposite script.
4. Press the same hotkey again to convert it back.

This repo currently contains the tested core conversion engine and a small command-line harness. The global hotkey/menu bar app will be built on top of this core.

## Current Status

- Core library: working
- Simplified to Traditional: working
- Traditional to Simplified: working
- Repeat toggle back to original script: working
- Mixed English/Chinese text: working
- macOS global hotkey app: next

## Build

```sh
swift build
```

## Test

```sh
swift test
```

## Try the CLI

```sh
swift run hantoggle "这句话是简体中文。"
swift run hantoggle "這句話是簡體中文。"
```

The CLI is mainly a development harness. The final app should use the same core library from a background macOS menu-bar utility.

## Architecture

- `HanToggle`: core Swift library.
- `ScriptToggler`: converts input to the opposite Chinese script using OpenCC dictionaries.
- `hantoggle`: tiny command-line wrapper for local testing.

The core uses `SwiftyOpenCC`, pinned to an exact tag for reproducible builds.

## License

MIT
