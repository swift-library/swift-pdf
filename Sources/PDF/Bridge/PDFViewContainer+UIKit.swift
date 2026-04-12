#if canImport(UIKit)
  import PDFKit
  import UIKit
  import SwiftUI

  @MainActor
  extension PDFViewContainer: UIViewRepresentable {
    public func makeCoordinator() -> Coordinator {
      Coordinator()
    }

    public func makeUIView(context: Context) -> PDFView {
      makePDFView(bindingWith: context.coordinator)
    }

    public func updateUIView(_ pdfView: PDFView, context: Context) {
      updatePDFView(pdfView, bindingWith: context.coordinator)
    }

    public static func dismantleUIView(_ uiView: PDFView, coordinator: Coordinator) {
      coordinator.detach()
    }
  }
#endif
