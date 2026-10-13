# Architecture

The `PDF` module is a SwiftUI viewer over PDFKit. Its public surface consists
of `PDF`, `PDFViewReader`, `PDFViewProxy`, document representations, and the
`.pdf` modifier namespace. `PDFViewContainer` and its coordinator are internal
integration types.

## Input and command paths

Modifiers write feature-scoped environment keys. `PDFViewContainer` reads the
raw environment, merges configuration, and assembles `PDFPageBindings`,
`PDFSearchBindings`, and `PDFPageOverlayViewCallbacks`. These payloads retain
binding and callback semantics; feature implementations do not read the
SwiftUI environment directly.

Commands travel from `PDFViewReader` through `PDFViewProxy` and its
session-bound `PDFViewProxyRelay` to feature code and PDFKit. Page and search
output bindings report settled state; assigning them does not imply a command.

## Ownership

Paths below are relative to `Sources/PDF/`. These directories are implementation
areas within one Swift module.

| Area | Owns | Main implementation |
| --- | --- | --- |
| Document | Representation identity, loading and mounting `pdfView.document` | `Document/PDFDocument+CachedLoader.swift` |
| Configuration | Merged rendering settings and property-level write deduplication | `Configuration/PDFViewConfiguration.swift`, `PDFView+Configuration.swift` |
| Page | Clamped navigation and settled page/count/scale publication | `Page/PDFView+PageNavigation.swift`, `PDFView+PageState.swift` |
| Search | Document-scoped query state and result publication | `Search/PDFSearchEngine.swift`, `PDFSearchBindingDriver.swift` |
| PageOverlay | Provider wiring, overlay host registry and create/refresh/release lifecycle | `PageOverlay/PDFPageOverlayViewProvider.swift`, `PDFPageOverlayViewLifecycle.swift`, `PDFPageOverlayViewRegistry.swift` |
| Bridge | Representable lifecycle, observer tokens, proxy attachment and callback adaptation | `Bridge/PDFViewContainer+Coordinator.swift` and platform adapters |

`Base/` contains the facade and container shell. `ViewModifier/` contains only
namespace, modifier and environment syntax, organized by feature. `Utility/`
contains shared leaf primitives such as binding write deduplication; it owns
no feature state or lifecycle.

Each mutable feature state has one owner. The coordinator sequences owners and
retains lifecycle collaborators; it does not become a second search engine,
overlay registry or binding publisher. Direct PDFKit dispatch is appropriate
when the feature has already resolved its state, clamp and publication rules.
A wrapper is not required merely to repeat an ownership name.

## Platform boundaries

UIKit and AppKit conformance files adapt native APIs while common types own
shared behavior. AppKit defers binding publication until after native layout;
UIKit publishes immediately and also observes visible-page changes to handle
continuous-mode navigation. Page-target dispatch and deferred publication in
the UIKit navigation path keep bindings synchronized as PDFKit settles.

Platform workarounds stay at the boundary responsible for the divergence.
Comments explain the observed timing or capability constraint, and behavior
tests cover the resulting public contract.

The package currently exposes viewer configuration, navigation, synchronous
search and page overlays. PDFKit's annotation editing, action handling,
thumbnail viewers, asynchronous search and document writing are not additional
public subsystems of this package.

See [Execution flows](ExecutionFlows.md) for sequencing, [Coding style](CodingStyle.md)
for implementation guidance, and [Versioning and release](VersioningAndRelease.md)
for compatibility requirements. The runnable [PDFViewer example](../../Examples/PDFViewer)
exercises navigation, search, markup and overlay telemetry with a generated PDF.
