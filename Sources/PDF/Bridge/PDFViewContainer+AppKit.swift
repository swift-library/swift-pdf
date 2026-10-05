#if canImport(AppKit)
  import AppKit
  import PDFKit
  import SwiftUI

  @MainActor
  extension PDFViewContainer: NSViewRepresentable {
    // PDFKit can publish page and scale changes while AppKit is still laying out
    // the representable. Defer outward SwiftUI binding writes until that native
    // update returns; this can become immediate only when AppKit permits those
    // writes without recursively invalidating the window constraint cycle.
    public func makeCoordinator() -> Coordinator {
      Coordinator()
    }

    public func makeNSView(context: Context) -> PDFView {
      makePDFView(
        bindingWith: context.coordinator,
        bindingPublicationTiming: .nextMainActorTurn
      )
    }

    public func updateNSView(_ pdfView: PDFView, context: Context) {
      updatePDFView(
        pdfView,
        bindingWith: context.coordinator,
        bindingPublicationTiming: .nextMainActorTurn
      )
    }

    public static func dismantleNSView(_ pdfView: PDFView, coordinator: Coordinator) {
      coordinator.detach()
    }
  }
#endif
