// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDFKit
import SwiftUI

@MainActor
extension PDFViewBase where Base: View {
  /// Supplies optional type-erased SwiftUI content for each page on the main actor.
  /// Returning `nil` removes that page's hosted overlay.
  public func overlay(_ provider: @escaping PDFPageOverlayViewContentProvider) -> some View {
    base.environment(
      \.pageOverlayContentProvider,
      PDFPageOverlayContentProviderEnvironmentValue(provider: provider)
    )
  }

  /// Builds SwiftUI content for each displayed page, refreshing it with viewer updates.
  public func overlay<Content: View>(
    @ViewBuilder _ content: @escaping (_ page: PDFPage) -> Content
  ) -> some View {
    base.environment(
      \.pageOverlayContentProvider,
      PDFPageOverlayContentProviderEnvironmentValue { page in
        AnyView(content(page))
      }
    )
  }

  /// Registers main-actor cleanup when a page's overlay leaves its hosting lifecycle.
  /// Use it to release resources associated with the supplied page.
  public func overlayRelease(_ release: @escaping PDFPageOverlayViewRelease) -> some View {
    base.environment(
      \.pageOverlayRelease,
      PDFPageOverlayReleaseEnvironmentValue(release: release)
    )
  }
}
