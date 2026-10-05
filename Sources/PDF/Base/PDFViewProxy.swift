// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import CoreGraphics
import PDFKit

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

  public init() {
    _storage = Storage()
  }

  public func goToPage(at pageIndex: Int) {
    relay?.goToPage(at: pageIndex)
  }

  public func goToNextPage() {
    relay?.goToNextPage()
  }

  public func goToPreviousPage() {
    relay?.goToPreviousPage()
  }

  public func goToFirstPage() {
    relay?.goToFirstPage()
  }

  public func goToLastPage() {
    relay?.goToLastPage()
  }

  public func goToSearchResult(at index: Int) {
    relay?.goToSearchResult(at: index)
  }

  public func goToNextSearchResult() {
    relay?.goToNextSearchResult()
  }

  public func goToPreviousSearchResult() {
    relay?.goToPreviousSearchResult()
  }

  public func goToSelection(_ selection: PDFSelection) {
    relay?.goToSelection(selection)
  }

  public func setScaleFactor(_ scaleFactor: CGFloat) {
    relay?.setScaleFactor(scaleFactor)
  }

  public func zoomIn() {
    relay?.zoomIn()
  }

  public func zoomOut() {
    relay?.zoomOut()
  }

  public func clearSelection() {
    relay?.clearSelection()
  }
}
