import CoreGraphics

public struct PDFSearchHit: Equatable, Sendable {
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
