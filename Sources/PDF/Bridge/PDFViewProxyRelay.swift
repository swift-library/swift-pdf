// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import CoreGraphics
import Dispatch
import PDFKit

@MainActor
final class PDFViewProxyRelay {
  private let pdfView: PDFView
  private let pageBindings: PDFPageBindings
  private let searchBindings: PDFSearchBindings
  private let searchBindingDriver: PDFSearchBindingDriver
  private let searchEngine: PDFSearchEngine?
  private var pagePublishWorkItem: DispatchWorkItem?

  init(
    pdfView: PDFView,
    pageBindings: PDFPageBindings,
    searchBindings: PDFSearchBindings,
    searchBindingDriver: PDFSearchBindingDriver,
    searchEngine: PDFSearchEngine?
  ) {
    self.pdfView = pdfView
    self.pageBindings = pageBindings
    self.searchBindings = searchBindings
    self.searchBindingDriver = searchBindingDriver
    self.searchEngine = searchEngine
  }

  func goToPage(at pageIndex: Int) {
    pdfView.goToPage(at: pageIndex)
    publishPageState()
  }

  func goToNextPage() {
    guard pdfView.canGoToNextPage else {
      return
    }

    pdfView.goToNextPage(nil)
    publishPageState()
  }

  func goToPreviousPage() {
    guard pdfView.canGoToPreviousPage else {
      return
    }

    pdfView.goToPreviousPage(nil)
    publishPageState()
  }

  func goToFirstPage() {
    pdfView.goToFirstPage()
    publishPageState()
  }

  func goToLastPage() {
    pdfView.goToLastPage()
    publishPageState()
  }

  func goToSearchResult(at index: Int) {
    guard let searchEngine,
      let selection = searchEngine.goToSearchResult(at: index)
    else {
      return
    }

    pdfView.goToSelection(selection)
    searchBindingDriver.publish(searchEngine.state, searchBindings: searchBindings)
    publishPageState()
  }

  func goToNextSearchResult() {
    guard let searchEngine,
      let selection = searchEngine.goToNextSearchResult()
    else {
      return
    }

    pdfView.goToSelection(selection)
    searchBindingDriver.publish(searchEngine.state, searchBindings: searchBindings)
    publishPageState()
  }

  func goToPreviousSearchResult() {
    guard let searchEngine,
      let selection = searchEngine.goToPreviousSearchResult()
    else {
      return
    }

    pdfView.goToSelection(selection)
    searchBindingDriver.publish(searchEngine.state, searchBindings: searchBindings)
    publishPageState()
  }

  func goToSelection(_ selection: PDFSelection) {
    pdfView.goToSelection(selection)
    publishPageState()
  }

  func setScaleFactor(_ scaleFactor: CGFloat) {
    pdfView.setScaleFactor(scaleFactor)
    publishPageState()
  }

  func zoomIn() {
    pdfView.zoomIn(nil)
    publishPageState()
  }

  func zoomOut() {
    pdfView.zoomOut(nil)
    publishPageState()
  }

  func clearSelection() {
    pdfView.setCurrentSelection(nil, animate: false)

    let state = searchEngine.map { $0.clearSelection() } ?? PDFSearchEngine.State()
    searchBindingDriver.publish(state, searchBindings: searchBindings)
  }

  private func publishPageState() {
    pagePublishWorkItem?.cancel()

    let pagePublishWorkItem = DispatchWorkItem { [weak self] in
      self.map { $0.pdfView.publishState($0.pageBindings) }
    }

    self.pagePublishWorkItem = pagePublishWorkItem
    // UIKit can lag one or more main-queue turns before currentPage/visible pages settle
    // after a navigation command. Defer the fallback state publish so SwiftUI bindings
    // resynchronize with PDFView instead of briefly reading the pre-navigation page.
    DispatchQueue.main.async {
      DispatchQueue.main.async(execute: pagePublishWorkItem)
    }
  }
}
