import PDFKit
import CoreGraphics
import Foundation

@MainActor
final class PDFSearchRuntime {
  struct RefreshResult {
    let didRefresh: Bool
    let navigationTarget: PDFSelection?
  }

  struct Snapshot {
    let currentSelectionIndex: Int?
    let resultCount: Int
    let hits: [PDFSearchHit]
  }

  private var activeQuery: String = ""
  private var activeOptions: NSString.CompareOptions = []

  private var searchSelections: [PDFSelection] = []
  private var searchHits: [PDFSearchHit] = []
  private var currentSelectionIndex: Int?

  private var shouldRefreshForDocumentChange: Bool = false

  func reset() {
    activeQuery = ""
    activeOptions = []
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

  func refreshIfNeeded(
    on pdfView: PDFView?,
    query: String,
    options: NSString.CompareOptions
  ) -> RefreshResult {
    let shouldRefresh = query != activeQuery || options != activeOptions || shouldRefreshForDocumentChange
    guard shouldRefresh else {
      return RefreshResult(didRefresh: false, navigationTarget: nil)
    }

    shouldRefreshForDocumentChange = false
    activeQuery = query
    activeOptions = options
    searchSelections.removeAll(keepingCapacity: false)
    searchHits.removeAll(keepingCapacity: false)
    currentSelectionIndex = nil

    guard !query.isEmpty else {
      pdfView?.setCurrentSelection(nil, animate: false)
      return RefreshResult(didRefresh: true, navigationTarget: nil)
    }

    guard let pdfView, let document = pdfView.document, document.pageCount > 0 else {
      return RefreshResult(didRefresh: true, navigationTarget: nil)
    }

    searchSelections = document.findString(query, withOptions: options)
    searchHits = makeHits(from: searchSelections)

    guard !searchSelections.isEmpty else {
      pdfView.setCurrentSelection(nil, animate: false)
      return RefreshResult(didRefresh: true, navigationTarget: nil)
    }

    return RefreshResult(
      didRefresh: true,
      navigationTarget: focusSelection(at: 0, on: pdfView)
    )
  }

  func clampedSelection(_ requestedSelection: Int) -> Int? {
    guard !searchSelections.isEmpty else {
      return nil
    }

    return min(max(requestedSelection, 0), searchSelections.count - 1)
  }

  func focusFirstResultIfNeeded(on pdfView: PDFView?) -> PDFSelection? {
    guard currentSelectionIndex == nil else {
      return nil
    }

    return focusSelection(at: 0, on: pdfView)
  }

  func focusSelection(at index: Int, on pdfView: PDFView?) -> PDFSelection? {
    guard let pdfView else {
      return nil
    }

    guard searchSelections.indices.contains(index) else {
      return nil
    }

    currentSelectionIndex = index
    let selection = searchSelections[index]
    pdfView.setCurrentSelection(selection, animate: true)
    return selection
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
