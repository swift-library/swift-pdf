// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDFKit

@MainActor
struct PDFPageOverlayViewCallbacks {
  var contentProvider: PDFPageOverlayViewContentProvider?
  var release: PDFPageOverlayViewRelease?

  init(
    contentProvider: PDFPageOverlayViewContentProvider? = nil,
    release: PDFPageOverlayViewRelease? = nil
  ) {
    self.contentProvider = contentProvider
    self.release = release
  }
}
