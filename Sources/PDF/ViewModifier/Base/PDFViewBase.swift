import PDFKit
import SwiftUI

/// A namespace for PDF-specific extensions.
public struct PDFViewBase<Base> {
  public let base: Base

  public init(_ base: Base) {
    self.base = base
  }
}

extension PDFViewBase: Sendable where Base: Sendable {}

extension View {
  public var pdf: PDFViewBase<Self> {
    .init(self)
  }
}
