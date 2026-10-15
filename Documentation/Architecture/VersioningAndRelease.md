# Versioning and Release

swift-pdf follows the [shared release standard](https://github.com/swift-library/.github/blob/master/VERSIONING.md).
`VERSION` declares the `PDF` library version, `CHANGELOG.md` records release
notes, and `.github/release.json` selects validation and compiler/platform inputs.

## Compatibility surface

Compatibility includes the PDF viewer, proxy commands, SwiftUI modifiers,
output bindings, overlay lifecycle and compiler/platform requirements.

## Requirements and validation

The package requires Swift 6.2, iOS 18, macOS 15 or visionOS 2. The maintained
system window covers iOS 18/26/27, macOS 15/26/27 and visionOS 2/26/27.
CI tests Swift 6.2 on macOS 15 and Swift 6.3 on macOS 26; strict formatting runs
separately. Native macOS 27 is an additional release check.

`Scripts/check` checks platform declarations, formatting, platform-tool tests,
Swift tests, release builds, DocC with warnings treated as errors, compiling
documentation snippets, iOS simulator tests, visionOS simulator builds and the
PDFViewer example. `Scripts/prepare-ci-platforms` prepares simulator components
and chooses the installed iOS test destination. Evidence belongs in
`.build/release-validation`.

Simulator tests start only after the selected device finishes booting. An
isolated GitHub-hosted runner can reinitialize the selected Xcode's simulator
service once after a startup failure, then retry booting the same device and
runtime. Each boot attempt has a five-minute deadline; recovery and a second
failure propagate. Local and self-hosted machines never reset host-wide
services. The boot log and attempt count accompany validation evidence.

README owns the package entry point. `Sources/PDF/PDF.docc` owns module
documentation and compiler-checked usage examples.
