// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import CoreGraphics
import PDFKit

/// Main-actor commands for a viewer connected through ``PDFViewReader``.
///
/// Copies share the same connection. Commands have no effect when no viewer is
/// attached; page and scale bindings report the settled PDFKit state asynchronously.
@MainActor
public struct PDFViewProxy {
  final class Storage {
    var relay: PDFViewProxyRelay?
  }

  private let _storage: Storage

  var relay: PDFViewProxyRelay? {
    get {
      _storage.relay
    }
    nonmutating set {
      _storage.relay = newValue
    }
  }

  /// Creates a disconnected proxy. Use a reader-supplied proxy to control a viewer.
  public init() {
    _storage = Storage()
  }

  /// Navigates to a zero-based page index, clamped to the document bounds.
  /// An empty or absent document leaves the view unchanged.
  public func goToPage(at pageIndex: Int) {
    relay?.goToPage(at: pageIndex)
  }

  /// Advances one page when PDFKit can navigate forward.
  public func goToNextPage() {
    relay?.goToNextPage()
  }

  /// Moves back one page when PDFKit can navigate backward.
  public func goToPreviousPage() {
    relay?.goToPreviousPage()
  }

  /// Navigates to the first page of the attached document.
  public func goToFirstPage() {
    relay?.goToFirstPage()
  }

  /// Navigates to the last page of the attached document.
  public func goToLastPage() {
    relay?.goToLastPage()
  }

  /// Selects and reveals a search result, clamping its zero-based index to the matches.
  /// Does nothing when there are no matches.
  public func goToSearchResult(at index: Int) {
    relay?.goToSearchResult(at: index)
  }

  /// Selects the next match, wrapping at the end; starts at the first when none is selected.
  public func goToNextSearchResult() {
    relay?.goToNextSearchResult()
  }

  /// Selects the preceding match, wrapping at the start; starts at the last when none is selected.
  public func goToPreviousSearchResult() {
    relay?.goToPreviousSearchResult()
  }

  /// Highlights a PDFKit selection and navigates to it in the attached viewer.
  public func goToSelection(_ selection: PDFSelection) {
    relay?.goToSelection(selection)
  }

  /// Sets the viewer scale, clamped when PDFKit supplies valid minimum and maximum factors.
  /// The scale binding reports the resulting value after PDFKit settles.
  public func setScaleFactor(_ scaleFactor: CGFloat) {
    relay?.setScaleFactor(scaleFactor)
  }

  /// Applies PDFKit's next zoom-in step to the attached viewer.
  public func zoomIn() {
    relay?.zoomIn()
  }

  /// Applies PDFKit's next zoom-out step to the attached viewer.
  public func zoomOut() {
    relay?.zoomOut()
  }

  /// Clears the visible selection and selected search-result index, retaining the matches.
  public func clearSelection() {
    relay?.clearSelection()
  }
}
