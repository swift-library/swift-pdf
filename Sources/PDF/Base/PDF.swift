import PDFKit
import SwiftUI

@MainActor
public struct PDF: View {
  private let source: PDFDocumentSource

  public init(source: PDFDocumentSource) {
    self.source = source
  }

  public init(document: PDFDocument) {
    self.init(source: .document(document))
  }

  public var body: some View {
    PDFViewContainer(source: source)
  }
}
