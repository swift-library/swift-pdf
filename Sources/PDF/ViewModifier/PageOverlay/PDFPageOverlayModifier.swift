// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDFKit
import SwiftUI

@MainActor
extension PDFViewBase where Base: View {
  public func overlay(_ provider: @escaping PDFPageOverlayViewContentProvider) -> some View {
    base.environment(
      \.pageOverlayContentProvider,
      PDFPageOverlayContentProviderEnvironmentValue(provider: provider)
    )
  }

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

  public func overlayRelease(_ release: @escaping PDFPageOverlayViewRelease) -> some View {
    base.environment(
      \.pageOverlayRelease,
      PDFPageOverlayReleaseEnvironmentValue(release: release)
    )
  }
}
