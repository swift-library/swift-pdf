#if canImport(AppKit)
  import AppKit
  import PDFKit
  import SwiftUI

  @MainActor
  extension PDFViewContainer: NSViewRepresentable {
    public func makeCoordinator() -> Coordinator {
      Coordinator()
    }

    public func makeNSView(context: Context) -> PDFView {
      makePDFView(bindingWith: context.coordinator)
    }

    public func updateNSView(_ pdfView: PDFView, context: Context) {
      updatePDFView(pdfView, bindingWith: context.coordinator)
    }

    public static func dismantleNSView(_ nsView: PDFView, coordinator: Coordinator) {
      coordinator.detach()
    }
  }
#endif
