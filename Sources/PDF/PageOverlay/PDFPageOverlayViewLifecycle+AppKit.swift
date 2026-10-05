// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

#if canImport(AppKit)
  import AppKit
  import PDFKit

  extension PDFPageOverlayViewLifecycle {
    func overlayView(for page: PDFPage) -> NSView? {
      return viewRegistry.overlayView(for: page, contentProvider: contentProvider)
    }
  }
#endif
