import PDFKit
import Foundation

@MainActor
final class PDFSearchEngine {
  private let document: PDFDocument
  private var state = State()

  init(document: PDFDocument) {
    self.document = document
  }

  func decide(
    query: String,
    options: NSString.CompareOptions,
    selectionIndex: Int?
  ) -> Decision {
    let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if performFind(query: normalizedQuery, options: options) {
      guard !state.results.isEmpty else {
        return .clearSelection(publication)
      }
      guard let selection = state.focus(at: 0) else {
        return .publish(publication)
      }
      return .focus(selection, publication)
    }

    guard !state.results.isEmpty else {
      return .publish(publication)
    }

    let targetIndex: Int
    if let selectionIndex {
      targetIndex = min(max(selectionIndex, 0), state.selections.count - 1)
      guard state.selectionIndex != targetIndex else {
        return .publish(publication)
      }
    } else {
      guard state.selectionIndex == nil else {
        return .publish(publication)
      }
      targetIndex = 0
    }

    guard let selection = state.focus(at: targetIndex) else {
      return .publish(publication)
    }
    return .focus(selection, publication)
  }

  private func performFind(
    query: String,
    options: NSString.CompareOptions
  ) -> Bool {
    guard query != state.query || options != state.options else {
      return false
    }

    state.query = query
    state.options = options

    guard !query.isEmpty else {
      state.flush()
      return true
    }

    guard document.pageCount > 0 else {
      state.flush()
      return true
    }

    let selections = document.findString(query, withOptions: options)
    guard !selections.isEmpty else {
      state.flush()
      return true
    }

    state.selections = selections
    state.results = selections.enumerated().map(PDFSearchResult.init)
    state.selectionIndex = nil
    return true
  }

  private var publication: Decision.Publication {
    Decision.Publication(
      selectionIndex: state.selectionIndex,
      resultCount: state.results.count,
      results: state.results
    )
  }

}

private extension PDFSearchEngine {
  struct State {
    var query = ""
    var options: NSString.CompareOptions = []
    var selections: [PDFSelection] = []
    var results: [PDFSearchResult] = []
    var selectionIndex: Int?

    mutating func focus(at index: Int) -> PDFSelection? {
      guard selections.indices.contains(index) else {
        return nil
      }

      selectionIndex = index
      return selections[index]
    }

    mutating func flush() {
      selections = []
      results = []
      selectionIndex = nil
    }
  }
}

extension PDFSearchEngine {
  enum Decision {
    struct Publication {
      let selectionIndex: Int?
      let resultCount: Int
      let results: [PDFSearchResult]
    }

    case publish(Publication)
    case clearSelection(Publication)
    case focus(PDFSelection, Publication)

    var publication: Publication {
      switch self {
      case .publish(let publication), .clearSelection(let publication), .focus(_, let publication):
        return publication
      }
    }
  }
}
