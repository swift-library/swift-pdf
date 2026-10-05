import CoreText
import Foundation
import PDFKit
import SwiftUI

@testable import PDF

#if canImport(AppKit)
  import AppKit
#endif

@MainActor
func bindCoordinator(
  _ coordinator: PDFViewContainer.Coordinator,
  pdfView: PDFView,
  initialSource: PDFDocument.Representation,
  currentPageBinding: Binding<Int>?,
  pageCountBinding: Binding<Int>?,
  scaleFactorBinding: Binding<CGFloat>? = nil,
  searchQueryBinding: Binding<String>? = nil,
  searchResultIndexBinding: Binding<Int?>? = nil,
  searchResultCountBinding: Binding<Int>? = nil,
  searchOptionsBinding: Binding<NSString.CompareOptions>? = nil,
  searchResultsBinding: Binding<[PDFSearchResult]>? = nil,
  proxy: PDFViewProxy? = nil
) {
  coordinator.bind(
    view: pdfView,
    from: initialSource,
    pageBindings: PDFPageBindings(
      currentPage: currentPageBinding,
      pageCount: pageCountBinding,
      scaleFactor: scaleFactorBinding
    ),
    searchBindings: PDFSearchBindings(
      query: searchQueryBinding,
      searchResultIndex: searchResultIndexBinding,
      searchResultCount: searchResultCountBinding,
      options: searchOptionsBinding,
      results: searchResultsBinding
    ),
    proxy: proxy
  )
}

@MainActor
func makeProxy() -> PDFViewProxy {
  PDFViewProxy()
}

@MainActor
func createOverlayView(
  using coordinator: PDFViewContainer.Coordinator,
  in pdfView: PDFView,
  for page: PDFPage
) -> Bool {
  let provider: any PDFPageOverlayViewProvider = coordinator

  #if canImport(UIKit)
    return provider.pdfView(pdfView, overlayViewFor: page) != nil
  #elseif canImport(AppKit)
    return provider.pdfView(pdfView, overlayViewFor: page) != nil
  #endif
}

@MainActor
func endOverlayDisplay(
  using coordinator: PDFViewContainer.Coordinator,
  in pdfView: PDFView,
  for page: PDFPage
) {
  let provider: any PDFPageOverlayViewProvider = coordinator

  #if canImport(UIKit)
    provider.pdfView?(
      pdfView,
      willEndDisplayingOverlayView: UIView(frame: .zero),
      for: page
    )
  #elseif canImport(AppKit)
    provider.pdfView?(
      pdfView,
      willEndDisplayingOverlayView: NSView(frame: .zero),
      for: page
    )
  #endif
}

@MainActor
final class IntBindingBox {
  var value: Int

  init(_ value: Int) {
    self.value = value
  }
}

@MainActor
final class TrackingIntBindingBox {
  var value: Int
  var setCount: Int

  init(_ value: Int, setCount: Int = 0) {
    self.value = value
    self.setCount = setCount
  }
}

@MainActor
final class StringBindingBox {
  var value: String

  init(_ value: String) {
    self.value = value
  }
}

@MainActor
final class OptionalIntBindingBox {
  var value: Int?

  init(_ value: Int?) {
    self.value = value
  }
}

@MainActor
final class SearchOptionsBindingBox {
  var value: NSString.CompareOptions

  init(_ value: NSString.CompareOptions) {
    self.value = value
  }
}

@MainActor
final class SearchResultsBindingBox {
  var value: [PDFSearchResult]

  init(_ value: [PDFSearchResult]) {
    self.value = value
  }
}

@MainActor
func makeBinding(for box: IntBindingBox) -> Binding<Int> {
  Binding(
    get: { box.value },
    set: { box.value = $0 }
  )
}

@MainActor
func makeBinding(for box: TrackingIntBindingBox) -> Binding<Int> {
  Binding(
    get: { box.value },
    set: {
      box.value = $0
      box.setCount += 1
    }
  )
}

@MainActor
func makeBinding(for box: StringBindingBox) -> Binding<String> {
  Binding(
    get: { box.value },
    set: { box.value = $0 }
  )
}

@MainActor
func makeBinding(for box: OptionalIntBindingBox) -> Binding<Int?> {
  Binding(
    get: { box.value },
    set: { box.value = $0 }
  )
}

@MainActor
func makeBinding(for box: SearchOptionsBindingBox) -> Binding<NSString.CompareOptions> {
  Binding(
    get: { box.value },
    set: { box.value = $0 }
  )
}

@MainActor
func makeBinding(for box: SearchResultsBindingBox) -> Binding<[PDFSearchResult]> {
  Binding(
    get: { box.value },
    set: { box.value = $0 }
  )
}

@MainActor
func currentPageIndex(in pdfView: PDFView) -> Int {
  guard let document = pdfView.document, let currentPage = pdfView.currentPage else {
    return 0
  }

  return max(0, document.index(for: currentPage))
}

@MainActor
func flushMainActorTasks() async {
  await Task.yield()
  drainRunLoop()
  await Task.yield()
}

func drainRunLoop() {
  RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
}

@MainActor
class PDFKitSuite {
  deinit {
    drainRunLoop()
  }
}

@MainActor
final class TrackingNavigationPDFView: PDFView {
  var goToPageCallCount = 0
  var goToNextPageCallCount = 0
  var goToPreviousPageCallCount = 0
  var goToDestinationCallCount = 0

  override func go(to page: PDFPage) {
    goToPageCallCount += 1
    super.go(to: page)
  }

  override func goToNextPage(_ sender: Any?) {
    goToNextPageCallCount += 1
    super.goToNextPage(sender)
  }

  override func goToPreviousPage(_ sender: Any?) {
    goToPreviousPageCallCount += 1
    super.goToPreviousPage(sender)
  }

  override func go(to destination: PDFDestination) {
    goToDestinationCallCount += 1
    super.go(to: destination)
  }
}

@MainActor
final class NonDispatchingPDFView: PDFView {
  override func goToNextPage(_ sender: Any?) {}

  override func goToPreviousPage(_ sender: Any?) {}

  override func go(to destination: PDFDestination) {}

  override func setCurrentSelection(_ selection: PDFSelection?, animate: Bool) {}

  override func go(to selection: PDFSelection) {}
}

func fixturePDFURL() throws -> URL {
  let url = FileManager.default.temporaryDirectory
    .appendingPathComponent("swift-pdf-fixture-\(UUID().uuidString).pdf")
  try fixturePDFData().write(to: url)
  return url
}

/// A generated multi-page document whose pages carry searchable text.
func fixturePDFData(pageCount: Int = 4) -> Data {
  let data = NSMutableData()
  var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
  guard
    let consumer = CGDataConsumer(data: data as CFMutableData),
    let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
  else {
    return Data()
  }
  let font = CTFontCreateWithName("Helvetica" as CFString, 18, nil)
  for index in 0..<pageCount {
    context.beginPDFPage(nil)
    let lines = [
      "Page \(index + 1) of the generated fixture.",
      "An Apple a day keeps the viewer busy.",
    ]
    for (offset, line) in lines.enumerated() {
      let text = NSAttributedString(
        string: line,
        attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]
      )
      context.textPosition = CGPoint(x: 72, y: 720 - CGFloat(offset) * 28)
      CTLineDraw(CTLineCreateWithAttributedString(text), context)
    }
    context.endPDFPage()
  }
  context.closePDF()
  return data as Data
}
