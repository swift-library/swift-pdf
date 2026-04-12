import Foundation
import PDFKit

@MainActor
final class PDFSearchEngine {
  private let document: PDFDocument
  private(set) var state = State()

  init(document: PDFDocument) {
    self.document = document
  }

  func performFind(
    query: String,
    options: NSString.CompareOptions
  ) -> Bool {
    let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    let pageCount = document.pageCount

    guard normalizedQuery != state.query
      || options != state.options
      || pageCount != state.pageCount
    else {
      return false
    }

    state.query = normalizedQuery
    state.options = options
    state.pageCount = pageCount

    guard !normalizedQuery.isEmpty, pageCount > 0 else {
      state.flush()
      return true
    }

    state.selections = document.findString(normalizedQuery, withOptions: options)
    state.results = state.selections.enumerated().map { element in
      let index = element.offset
      let selection = element.element

      guard let page = selection.pages.first else {
        return PDFSearchResult(
          index: index,
          pageIndex: 0,
          bounds: .null,
          text: selection.string ?? ""
        )
      }

      let pageIndex = page.document.map { max(0, $0.index(for: page)) } ?? 0
      return PDFSearchResult(
        index: index,
        pageIndex: pageIndex,
        bounds: selection.bounds(for: page),
        text: selection.string ?? ""
      )
    }
    state.searchResultIndex = nil
    return true
  }

  func goToSearchResult(at index: Int) -> PDFSelection? {
    guard !state.selections.isEmpty else {
      return nil
    }

    let targetIndex = Swift.min(Swift.max(index, 0), state.selections.count - 1)
    state.searchResultIndex = targetIndex
    return state.selections[targetIndex]
  }

  func goToNextSearchResult() -> PDFSelection? {
    guard !state.selections.isEmpty else {
      return nil
    }

    let nextIndex = ((state.searchResultIndex ?? -1) + 1 + state.selections.count)
      % state.selections.count
    return goToSearchResult(at: nextIndex)
  }

  func goToPreviousSearchResult() -> PDFSelection? {
    guard !state.selections.isEmpty else {
      return nil
    }

    let previousIndex = ((state.searchResultIndex ?? 0) - 1 + state.selections.count)
      % state.selections.count
    return goToSearchResult(at: previousIndex)
  }

  func clearSelection() -> State {
    state.searchResultIndex = nil
    return state
  }
}

extension PDFSearchEngine {
  struct State {
    var query = ""
    var options: NSString.CompareOptions = []
    var pageCount = 0
    var selections: [PDFSelection] = []
    var results: [PDFSearchResult] = []
    var searchResultIndex: Int?

    var searchResultCount: Int {
      results.count
    }

    mutating func flush() {
      selections = []
      results = []
      searchResultIndex = nil
    }
  }
}
