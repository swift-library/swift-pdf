import SwiftUI

@MainActor
extension PDFViewBase where Base: View {
  public func currentPage(_ pageIndex: Binding<Int>) -> some View {
    base.environment(\.currentPageBinding, pageIndex)
  }

  public func pageCount(_ count: Binding<Int>) -> some View {
    base.environment(\.pageCountBinding, count)
  }

  public func scaleFactor(_ scaleFactor: Binding<CGFloat>) -> some View {
    base.environment(\.scaleFactorBinding, scaleFactor)
  }
}
