// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import SwiftUI

/// Supplies navigation and zoom commands for one descendant ``PDF`` viewer.
///
/// Keep one viewer in each reader scope. Commands take effect while that viewer
/// is attached; the proxy does not retain a command queue for later attachment.
@MainActor
public struct PDFViewReader<Content: View>: View {
  @State private var proxy = PDFViewProxy()

  private let content: (PDFViewProxy) -> Content

  /// Builds content with a proxy whose connection follows the descendant viewer lifecycle.
  public init(
    @ViewBuilder content: @escaping (_ proxy: PDFViewProxy) -> Content
  ) {
    self.content = content
  }

  /// The content with its viewer proxy installed in the SwiftUI environment.
  public var body: some View {
    content(proxy)
      .environment(\.pdfViewProxy, proxy)
  }
}

extension EnvironmentValues {
  @Entry
  var pdfViewProxy: PDFViewProxy? = nil
}
