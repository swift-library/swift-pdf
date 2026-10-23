# Release

Release validation and publication use the shared
[GitHub workflows](https://github.com/swift-library/github-workflows).

Version rules for swift-pdf, covering tags, release timing, choosing the
next version and the changelog, are in
[VERSIONING](https://github.com/swift-library/.github/blob/master/VERSIONING.md).
This document records the repository's release facts and mechanics and does
not restate those rules.

README owns the package entry point. `Sources/PDF/PDF.docc` owns module
documentation and usage examples.

## Components and Version Sources

| Shipped component | Version meaning | Version source | Mirrors and derived fields | Update and read-only check |
| --- | --- | --- | --- | --- |
| `PDF` library | Library version | [`VERSION`](../../VERSION), named by `version_file` in [`.github/release.json`](../../.github/release.json) | [`CHANGELOG.md`](../../CHANGELOG.md) records release notes. | Update the declaration and changelog together; the shared policy workflow validates them. |

## Compatibility Surface

Compatibility includes the PDF viewer, proxy commands, SwiftUI modifiers,
output bindings, overlay lifecycle and compiler/platform requirements.

## Dependencies and Verified Combinations

The package requires Swift 6.3, iOS 18, macOS 15 or visionOS 2. The maintained
system window covers iOS 18/26/27, macOS 15/26/27 and visionOS 2/26/27.
CI compiles and tests with Xcode 26.6 (Swift 6.3) on macOS 26; strict formatting
runs separately. The latest SDK checks API availability for older supported
systems at compile time. Native macOS 27 is an additional release check.

## Derived Metadata and Drift Checks

[`.github/release.json`](../../.github/release.json) declares the repository,
version source, changelog, minimum Swift version, and supported platform window.

[`.github/swift-package.json`](../../.github/swift-package.json) declares the
CI compiler and formatting paths. The shared workflow runs strict
formatting, Swift tests and release builds on the declared compiler, iOS
generic builds and simulator tests, a generic visionOS build, and DocC for
`PDF` with warnings treated as errors. Apple and DocC jobs use the declared
compiler's runner and Xcode.

The required checks are `policy / policy` and `validate / result`.

## Candidate, Acceptance and Publication

Run the [local contribution checks](../../CONTRIBUTING.md) for the accepted
source and require successful shared CI validation. Pushing its signed
annotated `vX.Y.Z` tag starts the [Release](../../.github/workflows/release.yml)
workflow. It validates the tagged commit, verifies the tag, version declaration
and changelog, and publishes the changelog notes as a GitHub release.

## Entry Points and Artifact Retention

| Operation | Existing command or explicit manual procedure | Required access |
| --- | --- | --- |
| Version update and check | Update `VERSION` and `CHANGELOG.md`; the shared policy workflow validates them. | Repository write access |
| Candidate validation and build | Local checks in `CONTRIBUTING.md`; shared [CI](../../.github/workflows/ci.yml). | Local Swift and Xcode toolchains; GitHub Actions for CI |
| Status and interrupted-run recovery | Not established. | Not established. |
| Acceptance and publication | Push the accepted signed annotated tag to start [`Release`](../../.github/workflows/release.yml). | Repository write access to push tags |
| Cleanup | Not established. | Not established. |

Local SwiftPM builds and shared DocC output live under `.build/`.
