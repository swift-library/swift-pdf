// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

#if canImport(UIKit)
  import PDFKit
  import UIKit

  extension PDFPageOverlayViewLifecycle {
    func overlayView(for page: PDFPage) -> UIView? {
      return viewRegistry.overlayView(for: page, contentProvider: contentProvider)
    }
  }
#endif
