# Release

Release status: partly manual; `Scripts/check` implements validation, and native
macOS 27 is an additional release check.

Version rules for swift-pdf, covering tags, release timing, choosing the
next version and the changelog, are in
[VERSIONING](https://github.com/swift-library/.github/blob/master/VERSIONING.md).
This document records the repository's release facts and mechanics and does
not restate those rules.

README owns the package entry point. `Sources/PDF/PDF.docc` owns module
documentation and compiler-checked usage examples.

## Components and Version Sources

| Shipped component | Version meaning | Version source | Mirrors and derived fields | Update and read-only check |
| --- | --- | --- | --- | --- |
| `PDF` library | Library version | [`VERSION`](../../VERSION) | [`CHANGELOG.md`](../../CHANGELOG.md) records release notes. | Not established. |

## Compatibility Surface

Compatibility includes the PDF viewer, proxy commands, SwiftUI modifiers,
output bindings, overlay lifecycle and compiler/platform requirements.

## Dependencies and Verified Combinations

The package requires Swift 6.2, iOS 18, macOS 15 or visionOS 2. The maintained
system window covers iOS 18/26/27, macOS 15/26/27 and visionOS 2/26/27.
CI tests Swift 6.2 on macOS 15 and Swift 6.3 on macOS 26; strict formatting runs
separately. Native macOS 27 is an additional release check.

## Derived Metadata and Drift Checks

`.github/release.json` selects validation and compiler/platform inputs.

`Scripts/check` checks platform declarations, formatting, platform-tool tests,
Swift tests, release builds, DocC with warnings treated as errors, compiling
documentation snippets, iOS simulator tests, visionOS simulator builds and the
PDFViewer example.

## Candidate, Acceptance and Publication

Run `Scripts/check` for the accepted source.

## Evidence Reuse and Invalidation

Retain native, platform and consumer evidence for the accepted source.

Simulator tests start only after the selected device finishes booting. An
isolated GitHub-hosted runner can reinitialize the selected Xcode's simulator
service once after a startup failure, then retry booting the same device and
runtime. Each boot attempt has a five-minute deadline; recovery and a second
failure propagate. Local and self-hosted machines never reset host-wide
services. The boot log and attempt count accompany validation evidence.

## Entry Points and Artifact Retention

| Operation | Existing command or explicit manual procedure | Required access |
| --- | --- | --- |
| Version update and check | Not established. | Not established. |
| Candidate validation and build | `Scripts/prepare-ci-platforms`; `Scripts/check` | Not established. |
| Status and interrupted-run recovery | Not established. | Not established. |
| Acceptance and publication | Not established. | Not established. |
| Cleanup | Not established. | Not established. |

`Scripts/prepare-ci-platforms` prepares simulator components and chooses the
installed iOS test destination. Evidence belongs in `.build/release-validation`.
