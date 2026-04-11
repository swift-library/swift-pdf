import PDFKit
import SwiftUI

@MainActor
public struct PDF: View {
  private let source: PDFDocument.Representation

  public init(source: PDFDocument.Representation) {
    self.source = source
  }

  public init(document: PDFDocument) {
    self.init(source: .document(document))
  }

  public var body: some View {
    PDFViewContainer(source: source)
  }
}
