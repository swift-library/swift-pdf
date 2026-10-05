// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

#if canImport(UIKit)
  import PDFKit
  import UIKit
  import SwiftUI

  @MainActor
  extension PDFViewContainer: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
      Coordinator()
    }

    func makeUIView(context: Context) -> PDFView {
      makePDFView(bindingWith: context.coordinator)
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
      updatePDFView(pdfView, bindingWith: context.coordinator)
    }

    static func dismantleUIView(_ uiView: PDFView, coordinator: Coordinator) {
      coordinator.detach()
    }
  }
#endif
