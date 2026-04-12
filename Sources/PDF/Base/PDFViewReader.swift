import SwiftUI

@MainActor
public struct PDFViewReader<Content: View>: View {
  @State private var proxy = PDFViewProxy()

  private let content: (PDFViewProxy) -> Content

  public init(
    @ViewBuilder content: @escaping (_ proxy: PDFViewProxy) -> Content
  ) {
    self.content = content
  }

  public var body: some View {
    content(proxy)
      .environment(\.pdfViewProxy, proxy)
  }
}

extension EnvironmentValues {
  @Entry
  var pdfViewProxy: PDFViewProxy? = nil
}
