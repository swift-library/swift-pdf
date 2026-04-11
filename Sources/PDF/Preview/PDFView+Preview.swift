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
        let phoneInsets = resolvedPhonePreviewInsets(from: proxy.safeAreaInsets)
        content
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(.top, phoneInsets.top)
          .padding(.bottom, phoneInsets.bottom)
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

    private func resolvedPhonePreviewInsets(from geometryInsets: EdgeInsets) -> EdgeInsets {
      #if canImport(UIKit)
        guard UIDevice.current.userInterfaceIdiom == .phone else {
          return .init(top: 0, leading: 0, bottom: 0, trailing: 0)
        }

        return .init(
          top: max(geometryInsets.top, keyWindowSafeAreaInsets.top),
          leading: 0,
          bottom: max(geometryInsets.bottom, keyWindowSafeAreaInsets.bottom),
          trailing: 0
        )
      #else
        return .init(top: 0, leading: 0, bottom: 0, trailing: 0)
      #endif
    }

    #if canImport(UIKit)
      private var keyWindowSafeAreaInsets: UIEdgeInsets {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

        for scene in windowScenes {
          if let keyWindow = scene.windows.first(where: \.isKeyWindow) {
            return keyWindow.safeAreaInsets
          }
        }

        if let firstWindow = windowScenes.first?.windows.first {
          return firstWindow.safeAreaInsets
        }

        return .zero
      }
    #endif
  }
#endif
