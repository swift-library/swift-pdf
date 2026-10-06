# ``PDF``

Display PDF documents in SwiftUI with PDFKit.

@Metadata {
  @PageImage(purpose: icon, source: "Logo.png", alt: "swift-pdf logo")
  @PageColor(red)
}

## Overview

Create a ``PDF/PDF`` from a document, data, or file URL. Configure a viewer
through the `.pdf` namespace, observe settled state through bindings, and send
navigation commands through ``PDFViewProxy`` inside ``PDFViewReader``.

## Topics

### Guides

- <doc:GettingStarted>
- <doc:PageOverlays>
- <doc:Search-article>

### Viewers

- ``PDF/PDF``
- ``PDF/PDF/init(source:)``
- ``PDF/PDF/init(document:)``
- ``PDF/PDF/body``
- ``PDFViewReader``
- ``PDFViewReader/init(content:)``
- ``PDFViewReader/body``

### Document Sources

- ``PDFDocument/Representation``
- ``PDFDocument/Representation/document(_:)``
- ``PDFDocument/Representation/data(_:)``
- ``PDFDocument/Representation/fileURL(_:)``

### Viewer Commands

- ``PDFViewProxy``
- ``PDFViewProxy/init()``
- ``PDFViewProxy/goToPage(at:)``
- ``PDFViewProxy/goToFirstPage()``
- ``PDFViewProxy/goToPreviousPage()``
- ``PDFViewProxy/goToNextPage()``
- ``PDFViewProxy/goToLastPage()``
- ``PDFViewProxy/goToSelection(_:)``
- ``PDFViewProxy/setScaleFactor(_:)``
- ``PDFViewProxy/zoomIn()``
- ``PDFViewProxy/zoomOut()``
- ``PDFViewProxy/clearSelection()``

### Configuration and Settled State

- ``View/pdf``
- ``PDFViewBase``
- ``PDFViewBase/displayMode(_:)``
- ``PDFViewBase/displayDirection(_:)``
- ``PDFViewBase/autoScales(_:)``
- ``PDFViewBase/isInMarkupMode(_:)``
- ``PDFViewBase/currentPage(_:)``
- ``PDFViewBase/pageCount(_:)``
- ``PDFViewBase/scaleFactor(_:)``

### Page Overlays

- ``PDFPageOverlayViewContentProvider``
- ``PDFPageOverlayViewRelease``
- ``PDFViewBase/overlay(_:)-(PDFPageOverlayViewContentProvider)``
- ``PDFViewBase/overlay(_:)-((PDFPage)->Content)``
- ``PDFViewBase/overlayRelease(_:)``

### Search

- ``PDFViewBase/searchQuery(_:)``
- ``PDFViewBase/searchOptions(_:)``
- ``PDFViewBase/searchResultIndex(_:)``
- ``PDFViewBase/searchResultCount(_:)``
- ``PDFViewBase/searchResults(_:)``
- ``PDFViewProxy/goToSearchResult(at:)``
- ``PDFViewProxy/goToNextSearchResult()``
- ``PDFViewProxy/goToPreviousSearchResult()``
- ``PDFSearchResult``
- ``PDFSearchResult/init(index:pageIndex:bounds:text:)``
- ``PDFSearchResult/index``
- ``PDFSearchResult/pageIndex``
- ``PDFSearchResult/bounds``
- ``PDFSearchResult/text``
