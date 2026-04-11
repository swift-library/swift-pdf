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
      makeConfiguredPDFView(coordinator: context.coordinator)
    }

    public func updateUIView(_ pdfView: PDFView, context: Context) {
      updateConfiguredPDFView(pdfView, coordinator: context.coordinator)
    }

    public static func dismantleUIView(_ uiView: PDFView, coordinator: Coordinator) {
      coordinator.detach()
    }
  }
#endif
