# Third-Party Notices

HanToggle uses the following third-party projects.

## SwiftyOpenCC

- Project: https://github.com/ddddxxx/SwiftyOpenCC
- Purpose: Swift package wrapper for OpenCC conversion.
- Version: 2.0.0-beta, pinned by `Package.resolved`.
- License: MIT License.

## OpenCC

- Project: https://github.com/BYVoid/OpenCC
- Purpose: Chinese Simplified/Traditional conversion engine and dictionaries.
- Bundled content: compiled conversion code and dictionary resources included through SwiftyOpenCC.
- License: Apache License 2.0.

## Lucide

- Project: https://github.com/lucide-icons/lucide
- Purpose: website proof-section icon SVG paths.
- Version: 1.21.0.
- License: ISC License.

## marisa-trie

- Project: https://github.com/s-yata/marisa-trie
- Purpose: trie data structure used by OpenCC dictionary handling.
- Source in dependency checkout: `OpenCC/deps/marisa-0.2.6`.
- License: BSD 2-Clause or LGPL 2.1-or-later. HanToggle relies on the permissive BSD 2-Clause terms for binary distribution.

## RapidJSON

- Project: https://github.com/Tencent/rapidjson
- Purpose: JSON parsing support vendored by OpenCC.
- Source in dependency checkout: `OpenCC/deps/rapidjson-1.1.0`.
- License: MIT License.

## TCLAP

- Project: https://tclap.sourceforge.net/
- Purpose: command-line parsing support vendored by OpenCC.
- Source in dependency checkout: `OpenCC/deps/tclap-1.2.2`.
- License: MIT-style permissive license.

## Release Check

Before each public release:

1. Run `swift package resolve`.
2. Confirm `Package.resolved` still pins SwiftyOpenCC to the expected version.
3. Inspect `.build/checkouts/SwiftyOpenCC/LICENSE`.
4. Inspect `.build/checkouts/SwiftyOpenCC/OpenCC/LICENSE`.
5. Inspect `.build/checkouts/SwiftyOpenCC/OpenCC/deps/*` for added or changed license files.
6. Update this file before publishing if the dependency tree changes.
