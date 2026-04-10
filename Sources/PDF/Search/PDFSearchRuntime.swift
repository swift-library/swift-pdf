import PDFKit
import Foundation

@MainActor
final class PDFSearchRuntime {
  struct Snapshot {
    let currentSelectionIndex: Int?
    let resultCount: Int
    let hits: [PDFSearchHit]
  }

  private var activeQuery: String = ""
  private var activeOptions: PDFSearchOptions = .default

  private var searchSelections: [PDFSelection] = []
  private var searchHits: [PDFSearchHit] = []
  private var currentSelectionIndex: Int?

  private var shouldRefreshForDocumentChange: Bool = false

  func reset() {
    activeQuery = ""
    activeOptions = .default
    searchSelections.removeAll(keepingCapacity: false)
    searchHits.removeAll(keepingCapacity: false)
    currentSelectionIndex = nil
    shouldRefreshForDocumentChange = false
  }

  func markDocumentChanged() {
    shouldRefreshForDocumentChange = true
  }

  var snapshot: Snapshot {
    Snapshot(
      currentSelectionIndex: currentSelectionIndex,
      resultCount: searchSelections.count,
      hits: searchHits
    )
  }

  func normalizedQuery(from rawQuery: String?) -> String {
    (rawQuery ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func refreshIfNeeded(on pdfView: PDFView?, query: String, options: PDFSearchOptions) -> Bool {
    let shouldRefresh = query != activeQuery || options != activeOptions || shouldRefreshForDocumentChange
    guard shouldRefresh else {
      return false
    }

    shouldRefreshForDocumentChange = false
    activeQuery = query
    activeOptions = options
    searchSelections.removeAll(keepingCapacity: false)
    searchHits.removeAll(keepingCapacity: false)
    currentSelectionIndex = nil

    guard !query.isEmpty else {
      pdfView?.setCurrentSelection(nil, animate: false)
      return true
    }

    guard let pdfView, let document = pdfView.document, document.pageCount > 0 else {
      return true
    }

    searchSelections = document.findString(query, withOptions: options.compareOptions)
    searchHits = makeHits(from: searchSelections)

    guard !searchSelections.isEmpty else {
      pdfView.setCurrentSelection(nil, animate: false)
      return true
    }

    _ = focusSelection(at: 0, on: pdfView)
    return true
  }

  func clampedSelection(_ requestedSelection: Int) -> Int? {
    guard !searchSelections.isEmpty else {
      return nil
    }

    return min(max(requestedSelection, 0), searchSelections.count - 1)
  }

  func focusFirstResultIfNeeded(on pdfView: PDFView?) -> Int? {
    guard currentSelectionIndex == nil else {
      return currentSelectionIndex
    }

    return focusSelection(at: 0, on: pdfView)
  }

  func focusSelection(at index: Int, on pdfView: PDFView?) -> Int? {
    guard let pdfView else {
      return currentSelectionIndex
    }

    guard searchSelections.indices.contains(index) else {
      return currentSelectionIndex
    }

    currentSelectionIndex = index
    let selection = searchSelections[index]
    pdfView.setCurrentSelection(selection, animate: true)

    if let page = selection.pages.first {
      let bounds = selection.bounds(for: page)
      if !bounds.isNull && !bounds.isEmpty {
        pdfView.go(to: bounds, on: page)
        return index
      }
    }

    pdfView.go(to: selection)
    return index
  }

  private func makeHits(from selections: [PDFSelection]) -> [PDFSearchHit] {
    selections.enumerated().map { offset, selection in
      guard let page = selection.pages.first else {
        return PDFSearchHit(index: offset, pageIndex: 0, bounds: .null, text: selection.string ?? "")
      }

      let pageIndex = page.document.map { max(0, $0.index(for: page)) } ?? 0
      let bounds = selection.bounds(for: page)
      return PDFSearchHit(
        index: offset,
        pageIndex: pageIndex,
        bounds: bounds,
        text: selection.string ?? ""
      )
    }
  }
}
