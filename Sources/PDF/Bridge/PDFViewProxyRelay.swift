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
    schedulePageStatePublish()
  }

  func goToNextPage() {
    guard pdfView.canGoToNextPage else {
      return
    }

    pdfView.goToNextPage(nil)
    schedulePageStatePublish()
  }

  func goToPreviousPage() {
    guard pdfView.canGoToPreviousPage else {
      return
    }

    pdfView.goToPreviousPage(nil)
    schedulePageStatePublish()
  }

  func goToFirstPage() {
    guard let destination = pdfView.destination(at: 0)
    else {
      return
    }

    pdfView.go(to: destination)
    schedulePageStatePublish()
  }

  func goToLastPage() {
    let pageCount = pdfView.document?.pageCount ?? 0
    guard pageCount > 0,
      let destination = pdfView.destination(at: pageCount - 1)
    else {
      return
    }

    pdfView.go(to: destination)
    schedulePageStatePublish()
  }

  func goToSearchResult(at index: Int) {
    guard let searchEngine,
      let selection = searchEngine.goToSearchResult(at: index)
    else {
      return
    }

    pdfView.goToSelection(selection)
    searchBindingDriver.publish(searchEngine.state, searchBindings: searchBindings)
    schedulePageStatePublish()
  }

  func goToNextSearchResult() {
    guard let searchEngine,
      let selection = searchEngine.goToNextSearchResult()
    else {
      return
    }

    pdfView.goToSelection(selection)
    searchBindingDriver.publish(searchEngine.state, searchBindings: searchBindings)
    schedulePageStatePublish()
  }

  func goToPreviousSearchResult() {
    guard let searchEngine,
      let selection = searchEngine.goToPreviousSearchResult()
    else {
      return
    }

    pdfView.goToSelection(selection)
    searchBindingDriver.publish(searchEngine.state, searchBindings: searchBindings)
    schedulePageStatePublish()
  }

  func goToSelection(_ selection: PDFSelection) {
    pdfView.goToSelection(selection)
    schedulePageStatePublish()
  }

  func setScaleFactor(_ scaleFactor: CGFloat) {
    pdfView.setScaleFactor(scaleFactor)
    schedulePageStatePublish()
  }

  func zoomIn() {
    pdfView.zoomIn(nil)
    schedulePageStatePublish()
  }

  func zoomOut() {
    pdfView.zoomOut(nil)
    schedulePageStatePublish()
  }

  func clearSelection() {
    pdfView.setCurrentSelection(nil, animate: false)

    let state = searchEngine.map { $0.clearSelection() } ?? PDFSearchEngine.State()
    searchBindingDriver.publish(state, searchBindings: searchBindings)
  }

  private func schedulePageStatePublish() {
    pagePublishWorkItem?.cancel()

    let pagePublishWorkItem = DispatchWorkItem { [weak self] in
      self.map { $0.pdfView.publishState($0.pageBindings) }
    }

    self.pagePublishWorkItem = pagePublishWorkItem
    DispatchQueue.main.async(execute: pagePublishWorkItem)
  }
}
