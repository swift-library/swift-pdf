import Foundation
import PDFKit
import SwiftUI

#if canImport(AppKit)
  import AppKit
#endif

@testable import PDF

@MainActor
func bindCoordinator(
  _ coordinator: PDFViewContainer.Coordinator,
  pdfView: PDFView,
  initialSource: PDFDocument.Representation,
  pageIndexBinding: Binding<Int>?,
  pageCountBinding: Binding<Int>?,
  searchQueryBinding: Binding<String>? = nil,
  searchSelectionBinding: Binding<Int?>? = nil,
  searchResultCountBinding: Binding<Int>? = nil,
  searchOptionsBinding: Binding<NSString.CompareOptions>? = nil,
  searchResultsBinding: Binding<[PDFSearchResult]>? = nil
) {
  coordinator.bind(
    view: pdfView,
    from: initialSource,
    pageBindings: PDFPageBindings(
      pageIndex: pageIndexBinding,
      pageCount: pageCountBinding
    ),
    searchBindings: PDFSearchBindings(
      query: searchQueryBinding,
      selection: searchSelectionBinding,
      resultCount: searchResultCountBinding,
      options: searchOptionsBinding,
      results: searchResultsBinding
    )
  )
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
  var goToNextPageCallCount = 0
  var goToPreviousPageCallCount = 0
  var goToDestinationCallCount = 0

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
  let fixtureURL = try repositoryRootURL()
    .appendingPathComponent("Tests/PDFTests/Fixtures/drawingwithquartz2d.pdf")

  guard FileManager.default.fileExists(atPath: fixtureURL.path) else {
    throw NSError(
      domain: "PDFTests",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Fixture file not found at \(fixtureURL.path)"]
    )
  }

  return fixtureURL
}

func repositoryRootURL() throws -> URL {
  let testFileURL = URL(fileURLWithPath: #filePath)
  let repositoryRoot = testFileURL
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()

  guard FileManager.default.fileExists(atPath: repositoryRoot.path) else {
    throw NSError(
      domain: "PDFTests",
      code: 2,
      userInfo: [NSLocalizedDescriptionKey: "Repository root not found at \(repositoryRoot.path)"]
    )
  }

  return repositoryRoot
}
