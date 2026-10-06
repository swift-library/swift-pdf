// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDFKit
import SwiftUI

/// A main-actor SwiftUI viewer backed by PDFKit.
///
/// Apply ``PDFViewBase`` modifiers to configure this viewer or its ancestors.
/// Failed data or URL loading leaves the viewer without a document; construct a
/// `PDFDocument` first when the interface needs to handle loading failures.
@MainActor
public struct PDF: View {
  private let source: PDFDocument.Representation

  /// Creates a viewer whose source is resolved by PDFKit when mounted or changed.
  public init(source: PDFDocument.Representation) {
    self.source = source
  }

  /// Displays the supplied document instance without copying its pages.
  public init(document: PDFDocument) {
    self.init(source: .document(document))
  }

  /// The platform PDFKit view, configured by the surrounding SwiftUI environment.
  public var body: some View {
    PDFViewContainer(source: source)
  }
}
