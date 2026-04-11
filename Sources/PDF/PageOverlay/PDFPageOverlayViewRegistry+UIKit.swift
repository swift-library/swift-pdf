#if canImport(UIKit)
  import PDFKit
  import SwiftUI
  import UIKit

  @MainActor
  struct PDFPageOverlayViewRegistryItem {
    let page: PDFPage
    let hostingController: UIHostingController<AnyView>

    func update(content: AnyView) {
      hostingController.rootView = content
    }

    func removeOverlayViewFromSuperview() {
      hostingController.view.removeFromSuperview()
    }

    var overlayView: UIView {
      hostingController.view
    }
  }

  extension PDFPageOverlayViewRegistry {
    mutating func overlayView(
      for page: PDFPage,
      contentProvider: @escaping PDFPageOverlayViewContentProvider
    ) -> UIView? {
      guard let content = contentProvider(page) else {
        return nil
      }

      return platformOverlayView(for: page, content: content)
    }

    private mutating func platformOverlayView(for page: PDFPage, content: AnyView) -> UIView {
      let pageIdentifier = ObjectIdentifier(page)

      if let registryItem = overlayViewRegistryItems[pageIdentifier] {
        registryItem.update(content: content)
        return registryItem.overlayView
      }

      let registryItem = makeOverlayView(for: page, content: content)
      overlayViewRegistryItems[pageIdentifier] = registryItem
      return registryItem.overlayView
    }

    private func makeOverlayView(
      for page: PDFPage,
      content: AnyView
    ) -> PDFPageOverlayViewRegistryItem {
      let hostingController = UIHostingController(rootView: content)
      hostingController.view.backgroundColor = .clear
      hostingController.view.isOpaque = false
      return PDFPageOverlayViewRegistryItem(page: page, hostingController: hostingController)
    }
  }
#endif
