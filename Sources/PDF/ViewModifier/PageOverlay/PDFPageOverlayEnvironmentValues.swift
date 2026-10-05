// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import SwiftUI

@MainActor
struct PDFPageOverlayContentProviderEnvironmentValue {
  let provider: PDFPageOverlayViewContentProvider
}

@MainActor
struct PDFPageOverlayReleaseEnvironmentValue {
  let release: PDFPageOverlayViewRelease
}

extension EnvironmentValues {
  @Entry
  var pageOverlayContentProvider: PDFPageOverlayContentProviderEnvironmentValue?

  @Entry
  var pageOverlayRelease: PDFPageOverlayReleaseEnvironmentValue?
}
