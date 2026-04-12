# PDF

`PDF` is a Swift Package that provides a SwiftUI-first, library-grade viewer facade over `PDFKit`.

Phase-1 focuses on a thin, reusable viewing foundation with clean seams for future interaction, annotation, writer, and processor phases.


## Current boundaries

- `PDFDocument.Representation`: document loading/input boundary (`PDFDocument`, `Data`, `URL`).
- `PDFKit`: current fixed viewer backend (no alternate backend abstraction in this phase).
- `PDFViewContainer`: SwiftUI host/container boundary (`PDFKit` bridge).
- `.pdf.displayMode(_:)` / `.pdf.displayDirection(_:)` / `.pdf.autoScales(_:)` / `.pdf.isInMarkupMode(_:)`: viewer configuration boundary.
- `.pdf.page(_:)` + `.pdf.pageCount(_:)`: declarative navigation boundary.
- `.pdf.searchQuery(_:)` + `.pdf.searchSelection(_:)` + `.pdf.searchResultCount(_:)` + `.pdf.searchOptions(_:)` + `.pdf.searchResults(_:)`: declarative search boundary, with search options bound as official `NSString.CompareOptions`.
- `.pdf.overlay(_:)`: per-page SwiftUI overlay hook boundary.

## Installation

Add the package as a local/remote dependency and import:

```swift
import PDF
```

## Basic usage

```swift
import PDFKit
import SwiftUI
import PDF

struct ReaderView: View {
    @State private var pageIndex = 0
    @State private var pageCount = 0
    @State private var searchQuery = ""
    @State private var searchSelection: Int? = nil
    @State private var searchResultCount = 0
    @State private var searchOptions: NSString.CompareOptions = [.caseInsensitive]
    @State private var searchResults: [PDFSearchResult] = []

    let source: PDFDocument.Representation

    var body: some View {
        PDF(source: source)
            .pdf.displayMode(.singlePageContinuous)
            .pdf.displayDirection(.vertical)
            .pdf.autoScales(true)
            .pdf.page($pageIndex)
            .pdf.pageCount($pageCount)
            .pdf.searchQuery($searchQuery)
            .pdf.searchSelection($searchSelection)
            .pdf.searchResultCount($searchResultCount)
            .pdf.searchOptions($searchOptions)
            .pdf.searchResults($searchResults)
    }
}
```

For subtree-wide defaults (multiple viewers), you can also use namespace modifiers:

```swift
VStack {
    PDF(source: sourceA)
    PDF(source: sourceB)
}
.pdf.displayMode(.singlePageContinuous)
.pdf.displayDirection(.vertical)
.pdf.autoScales(true)
```

## Declarative navigation

External controls update `page` directly. `PDF` will clamp invalid indices and publish the current page back through the same binding:

```swift
Button("First") { pageIndex = 0 }
Button("Prev") { pageIndex = max(0, pageIndex - 1) }
Button("Next") { pageIndex = min(max(pageCount - 1, 0), pageIndex + 1) }
Button("Last") {
    if pageCount > 0 {
        pageIndex = pageCount - 1
    }
}
```

## Declarative search

Bind search text and selection index directly:

```swift
TextField("Search", text: $searchQuery)

Button("Prev") {
    guard searchResultCount > 0 else { return }
    let current = searchSelection ?? 0
    searchSelection = (current - 1 + searchResultCount) % searchResultCount
}

Button("Next") {
    guard searchResultCount > 0 else { return }
    let current = searchSelection ?? -1
    searchSelection = (current + 1) % searchResultCount
}
```

Use official Foundation compare options when you need non-default matching behavior:

```swift
searchOptions = [.caseInsensitive]
searchOptions = [.caseInsensitive, .diacriticInsensitive]
searchOptions = []
```

If `.pdf.searchOptions(_:)` is not bound, search runs with `[]`.

## Overlay hooks

Attach a per-page SwiftUI overlay:

```swift
PDF(source: source)
    .pdf.overlay { page in
        Text(page.label ?? "")
            .font(.caption.monospaced())
            .padding(8)
            .background(.blue.opacity(0.75))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .pdf.overlayRelease { page in
        // cleanup for this page
    }
```

Overlay behavior is explicit by platform:

- iOS / visionOS / macOS: callbacks are forwarded to `PDFKit` page overlay hooks.
- `overlayRelease` is lifecycle-based: any overlay view lifecycle removal path triggers release.

## PDFKit function mapping

Detailed current API-to-PDFKit mapping is documented in

## Preview Fixture Policy

- Preview implementation code lives under `Sources/PDF/Preview` and is compile-gated by `PDF_INTERNAL_PREVIEW`.
- Shared preview/test fixture lives at `Tests/PDFTests/Fixtures/drawingwithquartz2d.pdf`.
- Previews resolve fixture files from the repository file system path, not from `Bundle.module`.
- `PDF` target does not declare `.process` / `.copy` resources for these files, so they are not packaged as SwiftPM target resources.
- To enable previews locally, add `PDF_INTERNAL_PREVIEW` to Swift compiler conditions
  (for example: `swift build -Xswiftc -DPDF_INTERNAL_PREVIEW`).

## Scope notes

- No demo/sample app in this phase.
- No download/cache/share flows in core.
- No writer/export/processor implementation yet.

## Repository Policy

- Local commit hook path: `.githooks`
- Commit policy CI workflow: `.github/workflows/commit-message.yml`
- Contributor policy: see `CONTRIBUTING.md`.
- Repository type: `swift-package`.
