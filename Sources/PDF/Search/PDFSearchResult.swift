// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import CoreGraphics
import PDFKit

/// A sendable snapshot of one match in the current search results.
///
/// A new query replaces the result set and its indexes. Bounds describe the
/// selection on its first page in PDF page coordinates.
public struct PDFSearchResult: Equatable, Sendable {
  /// The zero-based position in the current search result set.
  public let index: Int
  /// The zero-based index of the first page containing the match, or zero if unavailable.
  public let pageIndex: Int
  /// The match bounds in first-page PDF coordinates, or `.null` if the selection has no page.
  public let bounds: CGRect
  /// The selected text, or an empty string when PDFKit supplies none.
  public let text: String

  /// Stores a result snapshot without validating indexes or transforming its bounds.
  public init(index: Int, pageIndex: Int, bounds: CGRect, text: String) {
    self.index = index
    self.pageIndex = pageIndex
    self.bounds = bounds
    self.text = text
  }
}
