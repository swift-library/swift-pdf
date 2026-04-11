#if DEBUG && canImport(SwiftUI) && PDF_INTERNAL_PREVIEW
  import SwiftUI
  #if canImport(UIKit)
    import UIKit
  #endif

  #Preview("Fixture PDF (Interactive)") {
    PDFInteractivePreviewContainer {
      PDFViewInteractivePreview(source: .fileURL(PreviewFixtures.fixtureURL()!))
    }
  }

  @MainActor
  private struct PDFInteractivePreviewContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
      self.content = content()
    }

    var body: some View {
      GeometryReader { proxy in
        content
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(.top, phoneTopCompensation(safeTop: proxy.safeAreaInsets.top))
          .padding(.bottom, phoneBottomCompensation(safeBottom: proxy.safeAreaInsets.bottom))
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      }
      .frame(minHeight: minimumPreviewHeight)
    }

    private var minimumPreviewHeight: CGFloat {
      #if canImport(UIKit)
        if UIDevice.current.userInterfaceIdiom == .phone {
          return 844
        }
      #endif
      return 760
    }

    private func phoneTopCompensation(safeTop: CGFloat) -> CGFloat {
      #if canImport(UIKit)
        if UIDevice.current.userInterfaceIdiom == .phone {
          return max(safeTop, 59)
        }
      #endif
      return 0
    }

    private func phoneBottomCompensation(safeBottom: CGFloat) -> CGFloat {
      #if canImport(UIKit)
        if UIDevice.current.userInterfaceIdiom == .phone {
          return max(safeBottom, 34)
        }
      #endif
      return 0
    }
  }
#endif
