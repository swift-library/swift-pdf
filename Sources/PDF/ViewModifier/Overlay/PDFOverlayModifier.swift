import PDFKit
import SwiftUI

@MainActor
extension PDFViewBase where Base: View {
  public func overlay(_ provider: @escaping PDFPageOverlayContentProvider) -> some View {
    base.environment(\.pageOverlayContentProvider, provider)
  }

  public func overlay<Content: View>(
    @ViewBuilder _ content: @escaping (_ page: PDFPage) -> Content
  ) -> some View {
    base.environment(\.pageOverlayContentProvider) { page in
      AnyView(content(page))
    }
  }

  public func overlayRelease(_ release: @escaping PDFPageOverlayRelease) -> some View {
    base.environment(\.pageOverlayRelease, release)
  }
}
