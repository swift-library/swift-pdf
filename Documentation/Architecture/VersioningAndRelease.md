# Versioning and Release

This document owns the package's version declaration, compatibility policy,
system support window and release acceptance. It adopts the
[swift-library versioning standard](https://github.com/swift-library/.github/blob/master/VERSIONING.md).
Operational commands live in the [Release Guide](../Reference/ReleaseGuide.md).

## Version Authority and Compatibility

`VERSION` owns the repository release version for its library products.
`CHANGELOG.md` owns the matching release notes. `.github/release.json` identifies
these files and owns the package's CI selection. `Scripts/validate-version`
checks them and optionally an existing `vVERSION` tag at HEAD; it leaves version
inputs unchanged.

During 0.x, fixes and compatible additions increment PATCH, and incompatible
changes increment MINOR with an explicit upgrade note. From 1.0.0, compatible
additions increment MINOR and incompatible changes increment MAJOR. Reset lower
components when increasing MINOR or MAJOR. Optional previews use alpha.N, beta.N or rc.N with
positive sequence numbers.

Compatibility includes public Swift APIs, serialized output, and compiler/platform
requirements. Documentation, formatting and CI changes alone do not force a
product release. Library consumers use next-minor bounds during 0.x.

Strict formatting uses one declared formatter toolchain. Compiler compatibility
jobs run the compiler-check scope, and the separate format-check job enforces
the complete formatting configuration. Local checks run both scopes.

## Supported Environments

Package.swift declares iOS 18, macOS 15 and visionOS 2 deployment floors,
and Swift tools 6.2. The system support window contains iOS 18/26/27,
macOS 15/26/27 and visionOS 2/26/27.
Review the three most recent formal system generations when preparing a release.
Raise a floor through a reviewed compatibility release; existing releases retain
their original requirements.

Compiler requirements are maintained independently. CI tests the declared
minimum compiler on macOS 15 and a current hosted compiler on macOS 26. Native
macOS 27, iOS simulator tests and visionOS simulator builds are additional release gates. Record
the precise OS, compiler and SDK in the release evidence.

README owns the package entry point. Sources/PDF/PDF.docc owns module
documentation and compiler-checked usage examples.

## Candidate and Publication

Candidate checks cover strict formatting, release-tool tests, Swift tests,
Release builds, DocC with warnings treated as errors, compiling documentation
snippets, iOS simulator tests, visionOS simulator builds and the PDFViewer
example. Release acceptance requires clean committed source, passing CI and
a fresh remote consumer. Source ownership and dependency notices are reviewed
when dependencies or incorporated code change.

Validation records the commit/tree, lockfile digest, toolchain, OS, SDK, checker
digest and logs beneath `.build/release-validation`. CI retains those outputs
as artifacts; publication attaches the accepted evidence archive. Revalidate
changed source, dependencies, configuration and checks on the new candidate.

After candidate acceptance, create the immutable version tag and verify a
fresh consumer using its SemVer requirement. The release workflow validates
the existing tag, checks its accepted commit and release notes, then publishes
from a separate contents-write job. An interrupted draft can resume when its
notes and evidence agree. Tagged source corrections use a new version.

The latest released line is maintained by default. Weekly dependency and Action
updates receive compatibility, lockfile and CI review before merging. Security
reports use the private route in SECURITY.md. Existing source history and
third-party ownership notices retain their provenance role.
