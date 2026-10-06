# Getting Started

Create a viewer and connect page controls.

## Overview

Import `PDF`, `PDFKit`, and `SwiftUI`. Use ``PDFKit/PDFDocument/Representation``
to choose an existing document, PDF data, or a file URL. Page indexes start at
zero. A ``PDFViewReader`` connects one descendant viewer to its proxy.

```swift
import PDF
import PDFKit
import SwiftUI

@MainActor
struct DocumentReader: View {
  let document: PDFDocument
  @State private var currentPage = 0
  @State private var pageCount = 0
  @State private var scaleFactor: CGFloat = 1

  var body: some View {
    PDFViewReader { proxy in
      VStack {
        PDF(source: .document(document))
          .pdf.displayMode(.singlePageContinuous)
          .pdf.displayDirection(.vertical)
          .pdf.autoScales(true)
          .pdf.currentPage($currentPage)
          .pdf.pageCount($pageCount)
          .pdf.scaleFactor($scaleFactor)

        HStack {
          Button("Previous") { proxy.goToPreviousPage() }
          Text("Page \(currentPage + 1) of \(pageCount)")
          Button("Next") { proxy.goToNextPage() }
        }
      }
    }
  }
}
```

The page, count, and scale bindings publish PDFKit's settled viewer state.
Use proxy commands to navigate or change scale. An unattached proxy has no
viewer to receive commands.

## Document input

`PDF(source:)` accepts an existing document, PDF data, or a file URL. PDFKit
loads data and files. If your interface needs a loading error, create and
validate a `PDFDocument` before passing it to the viewer.

## Page and scale controls

Use the proxy to go to a page, the first or last page, or a PDFKit selection.
`goToPage(at:)` clamps an index to the document's page range. Next and previous
page commands stop at the document's ends. Use `setScaleFactor(_:)`, `zoomIn()`,
and `zoomOut()` for zoom controls, and observe the resulting scale through
`.pdf.scaleFactor`.

Configuration modifiers applied to a parent view become defaults for its
descendant viewers. Bindings and commands belong to a viewer's reader scope;
use a separate reader for each independently controlled viewer.
