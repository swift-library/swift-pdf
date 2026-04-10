import CoreGraphics
import Foundation

public struct PDFSearchOptions: Equatable, Sendable {
  public var caseInsensitive: Bool

  public init(caseInsensitive: Bool = true) {
    self.caseInsensitive = caseInsensitive
  }

  public static let `default` = PDFSearchOptions()
}

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

extension PDFSearchOptions {
  var compareOptions: NSString.CompareOptions {
    caseInsensitive ? [.caseInsensitive] : []
  }
}
