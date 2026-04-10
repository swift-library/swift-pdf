import SwiftUI

@MainActor
extension PDFViewBase where Base: View {
  public func page(_ index: Binding<Int>) -> some View {
    base.environment(\.pageIndexBinding, index)
  }

  public func pageCount(_ count: Binding<Int>) -> some View {
    base.environment(\.pageCountBinding, count)
  }
}
