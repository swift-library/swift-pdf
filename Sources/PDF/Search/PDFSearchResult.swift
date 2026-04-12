import CoreGraphics
import PDFKit

public struct PDFSearchResult: Equatable, Sendable {
  public let index: Int
  public let pageIndex: Int
  public let bounds: CGRect
  public let text: String

  public init(index: Int, pageIndex: Int, bounds: CGRect, text: String) {
    self.index = index
    self.pageIndex = pageIndex
    self.bounds = bounds
    self.text = text
  }
}

extension PDFSearchResult {
  init(_ entry: (offset: Int, element: PDFSelection)) {
    let index = entry.offset
    let selection = entry.element

    guard let page = selection.pages.first else {
      self.init(index: index, pageIndex: 0, bounds: .null, text: selection.string ?? "")
      return
    }

    let pageIndex = page.document.map { max(0, $0.index(for: page)) } ?? 0
    self.init(
      index: index,
      pageIndex: pageIndex,
      bounds: selection.bounds(for: page),
      text: selection.string ?? ""
    )
  }
}
