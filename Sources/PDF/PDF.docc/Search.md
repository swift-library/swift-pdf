# Search

Bind a query and navigate its matching selections.

## Overview

The query is trimmed of leading and trailing whitespace and newlines.
Changes to the trimmed query or compare options recompute results. Each ``PDFSearchResult``
contains a result index, a zero-based page index, bounds, and matched text.
Proxy commands select results and navigate the viewer.

```swift
import Foundation
import PDF
import PDFKit
import SwiftUI

@MainActor
struct SearchableReader: View {
  let document: PDFDocument
  @State private var query = ""
  @State private var resultIndex: Int?
  @State private var resultCount = 0
  @State private var results: [PDFSearchResult] = []
  @State private var options: NSString.CompareOptions = [.caseInsensitive]

  var body: some View {
    PDFViewReader { proxy in
      VStack {
        TextField("Search", text: $query)
        PDF(document: document)
          .pdf.autoScales(true)
          .pdf.searchQuery($query)
          .pdf.searchOptions($options)
          .pdf.searchResultIndex($resultIndex)
          .pdf.searchResultCount($resultCount)
          .pdf.searchResults($results)

        HStack {
          Button("Previous match") { proxy.goToPreviousSearchResult() }
          Text("\(resultCount) matches")
          Button("Next match") { proxy.goToNextSearchResult() }
          Button("Clear selection") { proxy.clearSelection() }
        }
      }
    }
  }
}
```

A query update publishes results without automatically navigating. Search
options default to `[]` when no options binding is supplied. Clearing the
selection clears its focused result index while preserving the query and
results. An empty or whitespace-only query clears the result state.

Next and previous result commands cycle through the matches. With no focused
match, Next selects the first result and Previous selects the last.
`goToSearchResult(at:)` clamps an index to the available result range.
Each result describes its selection’s first page, using that page’s coordinate
space for `bounds`.
