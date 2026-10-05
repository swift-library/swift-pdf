# Page Overlays

Attach SwiftUI content to each displayed PDF page.

## Overview

Apply `.pdf.overlay` to provide content for a PDFKit page. Use
`.pdf.overlayRelease` to release page resources when an overlay leaves its
view lifecycle. A viewer installs a page overlay provider when overlay
content is configured.

```swift
import PDF
import PDFKit
import SwiftUI

@MainActor
struct PageLabelReader: View {
  let document: PDFDocument
  let releasePageResources: (PDFPage) -> Void

  var body: some View {
    PDF(document: document)
      .pdf.autoScales(true)
      .pdf.overlay { page in
        Text(page.label ?? "")
          .font(.caption.monospaced())
          .padding(8)
          .background(.blue.opacity(0.75))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
      .pdf.overlayRelease { page in
        releasePageResources(page)
      }
  }
}
```

The content-provider overload returns `AnyView?`; return `nil` for pages
that need no overlay. Both overloads use PDFKit's page overlay hooks on iOS,
macOS, and visionOS. Release callbacks run on the main actor.
