import Foundation
import PDFKit
import SwiftUI
import Testing

#if canImport(AppKit)
  import AppKit
#endif

@testable import PDF

@Test
func documentSourceDocumentCasePreservesObjectIdentity() {
  let document = PDFDocument()
  let source = PDFDocumentSource.document(document)

  #expect(source.resolveDocument() === document)
}

@Test
func documentSourceDataCaseBuildsReadableDocument() throws {
  let fixtureData = try Data(contentsOf: fixturePDFURL())
  let source = PDFDocumentSource.data(fixtureData)

  let document = try #require(source.resolveDocument())
  #expect(document.pageCount > 0)
}

@Test
func documentSourceFileURLCaseBuildsReadableDocument() throws {
  let source = PDFDocumentSource.fileURL(try fixturePDFURL())

  let document = try #require(source.resolveDocument())
  #expect(document.pageCount > 0)
}

@Test
func viewerConfigurationDefaultsMatchExpectedFoundationValues() {
  let configuration = PDFViewConfiguration.default

  #expect(configuration.displayMode == .singlePage)
  #expect(configuration.displayDirection == .horizontal)
  #expect(configuration.isInMarkupMode == false)
}

@Test
func configurationBuilderSetsPDFViewOptionsInConfigurationValue() {
  let margins = PDFPageMargins(top: 1, left: 2, bottom: 3, right: 4)

  let configuration = PDFViewConfigurationBuilder.builder()
    .displayMode(PDFDisplayMode.twoUpContinuous)
    .displayDirection(PDFDisplayDirection.vertical)
    .isInMarkupMode(true)
    .autoScales(true)
    .displaysAsBook(true)
    .displaysPageBreaks(false)
    .displaysRTL(true)
    .minScaleFactor(0.5)
    .maxScaleFactor(4.0)
    .pageBreakMargins(margins)
    .pageShadowsEnabled(false)
    .build()

  #expect(configuration.displayMode == PDFDisplayMode.twoUpContinuous)
  #expect(configuration.displayDirection == PDFDisplayDirection.vertical)
  #expect(configuration.isInMarkupMode == true)
  #expect(configuration.autoScales == true)
  #expect(configuration.displaysAsBook == true)
  #expect(configuration.displaysPageBreaks == false)
  #expect(configuration.displaysRTL == true)
  #expect(configuration.minScaleFactor == 0.5)
  #expect(configuration.maxScaleFactor == 4.0)
  #expect(configuration.pageBreakMargins == margins)
  #expect(configuration.pageShadowsEnabled == false)
}

@Test
func configurationAndDisplayModifiersResolveWithoutOrderSensitivity() {
  let baseConfiguration = PDFViewConfigurationBuilder.builder()
    .displayMode(.singlePage)
    .displayDirection(.horizontal)
    .isInMarkupMode(false)
    .autoScales(true)
    .build()

  let resolver = PDFViewConfigurationResolver()

  var configurationFirstEnvironment = EnvironmentValues()
  configurationFirstEnvironment.viewConfiguration = baseConfiguration
  configurationFirstEnvironment.displayMode = .twoUpContinuous
  configurationFirstEnvironment.displayDirection = .vertical
  configurationFirstEnvironment.autoScales = false
  configurationFirstEnvironment.isInMarkupMode = true

  var modifiersFirstEnvironment = EnvironmentValues()
  modifiersFirstEnvironment.displayMode = .twoUpContinuous
  modifiersFirstEnvironment.displayDirection = .vertical
  modifiersFirstEnvironment.autoScales = false
  modifiersFirstEnvironment.isInMarkupMode = true
  modifiersFirstEnvironment.viewConfiguration = baseConfiguration

  let configurationFirstResolved = resolver.resolve(
    base: configurationFirstEnvironment.viewConfiguration,
    displayMode: configurationFirstEnvironment.displayMode,
    displayDirection: configurationFirstEnvironment.displayDirection,
    autoScales: configurationFirstEnvironment.autoScales,
    isInMarkupMode: configurationFirstEnvironment.isInMarkupMode
  )

  let modifiersFirstResolved = resolver.resolve(
    base: modifiersFirstEnvironment.viewConfiguration,
    displayMode: modifiersFirstEnvironment.displayMode,
    displayDirection: modifiersFirstEnvironment.displayDirection,
    autoScales: modifiersFirstEnvironment.autoScales,
    isInMarkupMode: modifiersFirstEnvironment.isInMarkupMode
  )

  #expect(configurationFirstResolved.displayMode == .twoUpContinuous)
  #expect(configurationFirstResolved.displayDirection == .vertical)
  #expect(configurationFirstResolved.autoScales == false)
  #expect(configurationFirstResolved.isInMarkupMode == true)

  #expect(modifiersFirstResolved.displayMode == configurationFirstResolved.displayMode)
  #expect(modifiersFirstResolved.displayDirection == configurationFirstResolved.displayDirection)
  #expect(modifiersFirstResolved.isInMarkupMode == configurationFirstResolved.isInMarkupMode)
  #expect(modifiersFirstResolved.autoScales == configurationFirstResolved.autoScales)
}

@Test
@MainActor
func pageBindingDrivesNavigationAndClampsOutOfRangeValues() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))
  #expect(document.pageCount > 0)

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  let pageIndexBox = IntBindingBox(0)
  let pageCountBox = IntBindingBox(0)

  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  #expect(pdfView.document === document)
  #expect(pageCountBox.value == document.pageCount)
  #expect(pageIndexBox.value == 0)

  pageIndexBox.value = document.pageCount + 99
  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  let lastPageIndex = max(0, document.pageCount - 1)
  #expect(pageIndexBox.value == lastPageIndex)
  #expect(currentPageIndex(in: pdfView) == lastPageIndex)

  pageIndexBox.value = -123
  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  #expect(pageIndexBox.value == 0)
  #expect(currentPageIndex(in: pdfView) == 0)
}

@Test
@MainActor
func internalPageChangesPublishBackIntoPageBinding() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))
  #expect(document.pageCount > 1)

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  let pageIndexBox = IntBindingBox(0)
  let pageCountBox = IntBindingBox(0)

  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  #expect(pageIndexBox.value == 0)
  #expect(pageCountBox.value == document.pageCount)

  pdfView.goToNextPage(nil)
  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  #expect(pageIndexBox.value == 1)
}

@Test
@MainActor
func searchBindingsPublishMatchesAndSupportSelectionControl() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))
  #expect(document.pageCount > 0)

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  let queryBox = StringBindingBox("the")
  let selectionBox = OptionalIntBindingBox(nil)
  let resultCountBox = IntBindingBox(0)
  let optionsBox = SearchOptionsBindingBox(.default)
  let resultsBox = SearchResultsBindingBox([])

  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: nil,
    pageCountBinding: nil,
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox),
    searchOptionsBinding: makeBinding(for: optionsBox),
    searchResultsBinding: makeBinding(for: resultsBox)
  )
  #expect(resultCountBox.value > 0)
  #expect(selectionBox.value == 0)
  #expect(resultsBox.value.count == resultCountBox.value)
  for (offset, hit) in resultsBox.value.enumerated() {
    #expect(hit.index == offset)
  }

  selectionBox.value = resultCountBox.value + 99
  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: nil,
    pageCountBinding: nil,
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox),
    searchOptionsBinding: makeBinding(for: optionsBox),
    searchResultsBinding: makeBinding(for: resultsBox)
  )
  #expect(selectionBox.value == max(0, resultCountBox.value - 1))
  if let selectedIndex = selectionBox.value, resultsBox.value.indices.contains(selectedIndex) {
    #expect(currentPageIndex(in: pdfView) == resultsBox.value[selectedIndex].pageIndex)
  }
}

@Test
@MainActor
func searchOptionsChangesTriggerRecomputationWithoutChangingQuery() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  let queryBox = StringBindingBox("apple")
  let selectionBox = OptionalIntBindingBox(nil)
  let resultCountBox = IntBindingBox(0)
  let optionsBox = SearchOptionsBindingBox(.default)
  let resultsBox = SearchResultsBindingBox([])

  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: nil,
    pageCountBinding: nil,
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox),
    searchOptionsBinding: makeBinding(for: optionsBox),
    searchResultsBinding: makeBinding(for: resultsBox)
  )

  #expect(resultCountBox.value > 0)
  #expect(resultsBox.value.count == resultCountBox.value)

  optionsBox.value = PDFSearchOptions(caseInsensitive: false)
  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: nil,
    pageCountBinding: nil,
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox),
    searchOptionsBinding: makeBinding(for: optionsBox),
    searchResultsBinding: makeBinding(for: resultsBox)
  )

  #expect(resultCountBox.value == 0)
  #expect(selectionBox.value == nil)
  #expect(resultsBox.value == [])
}

@Test
@MainActor
func clearingSearchQueryResetsSearchBindings() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  let queryBox = StringBindingBox("Quartz")
  let selectionBox = OptionalIntBindingBox(nil)
  let resultCountBox = IntBindingBox(0)
  let optionsBox = SearchOptionsBindingBox(.default)
  let resultsBox = SearchResultsBindingBox([])

  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: nil,
    pageCountBinding: nil,
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox),
    searchOptionsBinding: makeBinding(for: optionsBox),
    searchResultsBinding: makeBinding(for: resultsBox)
  )
  queryBox.value = ""
  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: nil,
    pageCountBinding: nil,
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox),
    searchOptionsBinding: makeBinding(for: optionsBox),
    searchResultsBinding: makeBinding(for: resultsBox)
  )
  #expect(resultCountBox.value == 0)
  #expect(selectionBox.value == nil)
  #expect(resultsBox.value == [])
}

@Test
@MainActor
func switchingDocumentRefreshesSearchBindingsAgainstNewDocument() throws {
  let populatedDocument = try #require(PDFDocument(url: fixturePDFURL()))
  let emptyDocument = PDFDocument()

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  let queryBox = StringBindingBox("the")
  let selectionBox = OptionalIntBindingBox(nil)
  let resultCountBox = IntBindingBox(0)
  let optionsBox = SearchOptionsBindingBox(.default)
  let resultsBox = SearchResultsBindingBox([])

  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(populatedDocument),
    pageIndexBinding: nil,
    pageCountBinding: nil,
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox),
    searchOptionsBinding: makeBinding(for: optionsBox),
    searchResultsBinding: makeBinding(for: resultsBox)
  )
  #expect(resultCountBox.value > 0)
  #expect(!resultsBox.value.isEmpty)

  coordinator.loadDocumentIfNeeded(.document(emptyDocument))

  #expect(pdfView.document === emptyDocument)
  #expect(resultCountBox.value == 0)
  #expect(selectionBox.value == nil)
  #expect(resultsBox.value == [])
}

@Test
@MainActor
func pageChangesDoNotResetSearchBindings() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))
  #expect(document.pageCount > 1)

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  let pageIndexBox = IntBindingBox(0)
  let pageCountBox = IntBindingBox(0)
  let queryBox = StringBindingBox("Quartz")
  let selectionBox = OptionalIntBindingBox(nil)
  let resultCountBox = IntBindingBox(0)

  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox),
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox)
  )
  let initialResultCount = resultCountBox.value
  let initialSelection = selectionBox.value
  #expect(initialResultCount > 0)

  pageIndexBox.value = 1
  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox),
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox)
  )
  #expect(queryBox.value == "Quartz")
  #expect(resultCountBox.value == initialResultCount)
  #expect(selectionBox.value == initialSelection)
}

@Test
@MainActor
func repeatedLoadWithSameDocumentDoesNotThrashSearchBindings() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))
  let emptyDocument = PDFDocument()

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  let queryBox = StringBindingBox("the")
  let selectionBox = OptionalIntBindingBox(nil)
  let resultCountBox = IntBindingBox(0)

  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: nil,
    pageCountBinding: nil,
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox)
  )
  #expect(resultCountBox.value > 0)

  coordinator.loadDocumentIfNeeded(.document(emptyDocument))
  #expect(resultCountBox.value == 0)
  #expect(selectionBox.value == nil)

  coordinator.loadDocumentIfNeeded(.document(emptyDocument))
  #expect(resultCountBox.value == 0)
  #expect(selectionBox.value == nil)
}

@Test
@MainActor
func previewStyleBindAndLoadCyclePublishesSearchBindings() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))
  #expect(document.pageCount > 0)

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  let queryBox = StringBindingBox("")
  let selectionBox = OptionalIntBindingBox(nil)
  let resultCountBox = IntBindingBox(0)

  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: nil,
    pageCountBinding: nil,
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox)
  )
  queryBox.value = "Quartz"
  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: nil,
    pageCountBinding: nil,
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox)
  )
  coordinator.loadDocumentIfNeeded(.document(document))

  #expect(resultCountBox.value > 0)
  #expect(selectionBox.value != nil)
}

@Test
@MainActor
func switchingToEmptyDocumentResetsPageCountAndPageIndexBindings() throws {
  let populatedDocument = try #require(PDFDocument(url: fixturePDFURL()))
  #expect(populatedDocument.pageCount > 0)

  let emptyDocument = PDFDocument()

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  let pageIndexBox = IntBindingBox(populatedDocument.pageCount + 10)
  let pageCountBox = IntBindingBox(0)

  coordinator.bind(
    pdfView: pdfView,
    initialSource: .document(populatedDocument),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  #expect(pageCountBox.value == populatedDocument.pageCount)
  #expect(pageIndexBox.value == max(0, populatedDocument.pageCount - 1))

  coordinator.loadDocumentIfNeeded(.document(emptyDocument))

  #expect(pdfView.document === emptyDocument)
  #expect(pageCountBox.value == 0)
  #expect(pageIndexBox.value == 0)
}

@Test
@MainActor
func coordinatorConformsToOverlayProviderOnCurrentPlatform() throws {
  let coordinator = PDFViewContainer.Coordinator()
  let provider: any PDFPageOverlayViewProvider = coordinator

  let document = try #require(PDFDocument(url: fixturePDFURL()))
  let page = try #require(document.page(at: 0))
  let pdfView = PDFView()

  #if canImport(UIKit)
    _ = provider.pdfView(pdfView, overlayViewFor: page)
    provider.pdfView?(
      pdfView,
      willEndDisplayingOverlayView: UIView(frame: .zero),
      for: page
    )
  #elseif canImport(AppKit)
    _ = provider.pdfView(pdfView, overlayViewFor: page)
    provider.pdfView?(
      pdfView,
      willEndDisplayingOverlayView: NSView(frame: .zero),
      for: page
    )
  #endif
}

@Test
@MainActor
func overlayRegistryRefreshRemovalTriggersRelease() throws {
  var registry = PDFOverlayHostRegistry()

  let document = try #require(PDFDocument(url: fixturePDFURL()))
  let page = try #require(document.page(at: 0))
  let pageID = ObjectIdentifier(page)

  let overlayView = registry.overlayView(for: page) { _ in
    AnyView(Color.red)
  }
  #expect(overlayView != nil)

  var released: [ObjectIdentifier] = []
  registry.refresh(
    contentProvider: { _ in nil },
    release: { released.append(ObjectIdentifier($0)) }
  )

  #expect(released == [pageID])
}

@Test
@MainActor
func overlayRegistryClearTriggersReleaseForAllHosts() throws {
  var registry = PDFOverlayHostRegistry()

  let document = try #require(PDFDocument(url: fixturePDFURL()))
  #expect(document.pageCount > 1)
  let page0 = try #require(document.page(at: 0))
  let page1 = try #require(document.page(at: 1))

  _ = registry.overlayView(for: page0) { _ in AnyView(Color.red) }
  _ = registry.overlayView(for: page1) { _ in AnyView(Color.blue) }

  var released = Set<ObjectIdentifier>()
  registry.clear(
    release: { released.insert(ObjectIdentifier($0)) }
  )

  #expect(released.count == 2)
  #expect(released.contains(ObjectIdentifier(page0)))
  #expect(released.contains(ObjectIdentifier(page1)))
}

@Test
@MainActor
func overlayRegistryReleaseIsNotDuplicatedAfterRefreshRemovalThenEndDisplay() throws {
  var registry = PDFOverlayHostRegistry()

  let document = try #require(PDFDocument(url: fixturePDFURL()))
  let page = try #require(document.page(at: 0))

  _ = registry.overlayView(for: page) { _ in
    AnyView(Color.red)
  }

  var releaseCount = 0
  registry.refresh(
    contentProvider: { _ in nil },
    release: { _ in releaseCount += 1 }
  )
  registry.didEndDisplayingOverlayView(
    for: page,
    release: { _ in releaseCount += 1 }
  )

  #expect(releaseCount == 1)
}

@Test
@MainActor
func primaryViewAndModifierSurfaceCompiles() {
  struct PrimarySurfaceView: View {
    @State private var pageIndex: Int = 0
    @State private var pageCount: Int = 0
    @State private var searchQuery: String = ""
    @State private var searchSelection: Int? = nil
    @State private var searchResultCount: Int = 0
    @State private var searchOptions: PDFSearchOptions = .default
    @State private var searchResults: [PDFSearchHit] = []

    var body: some View {
      PDF(document: PDFDocument())
        .pdf.displayMode(.twoUpContinuous)
        .pdf.displayDirection(.vertical)
        .pdf.isInMarkupMode(true)
        .pdf.configuration(
          PDFViewConfigurationBuilder.builder()
            .autoScales(true)
            .build()
        )
        .pdf.page($pageIndex)
        .pdf.pageCount($pageCount)
        .pdf.searchQuery($searchQuery)
        .pdf.searchSelection($searchSelection)
        .pdf.searchResultCount($searchResultCount)
        .pdf.searchOptions($searchOptions)
        .pdf.searchResults($searchResults)
        .pdf.overlay { _ in
          Color.clear
        }
        .pdf.overlayRelease { _ in }
    }
  }

  _ = PrimarySurfaceView().body
}

@Test
@MainActor
func shortPDFFacadeCompiles() {
  struct ShortPDFSurfaceView: View {
    var body: some View {
      PDF(document: PDFDocument())
    }
  }

  _ = ShortPDFSurfaceView().body
}

@Test
@MainActor
func pdfNamespaceModifierSurfaceCompiles() {
  struct NamespaceSurfaceView: View {
    @State private var pageIndex: Int = 0
    @State private var pageCount: Int = 0
    @State private var searchQuery: String = ""
    @State private var searchSelection: Int? = nil
    @State private var searchResultCount: Int = 0
    @State private var searchOptions: PDFSearchOptions = .default
    @State private var searchResults: [PDFSearchHit] = []

    var body: some View {
      VStack {
        PDF(document: PDFDocument())
      }
      .pdf.displayMode(.singlePageContinuous)
      .pdf.displayDirection(.vertical)
      .pdf.autoScales(true)
      .pdf.isInMarkupMode(true)
      .pdf.page($pageIndex)
      .pdf.pageCount($pageCount)
      .pdf.searchQuery($searchQuery)
      .pdf.searchSelection($searchSelection)
      .pdf.searchResultCount($searchResultCount)
      .pdf.searchOptions($searchOptions)
      .pdf.searchResults($searchResults)
      .pdf.overlay { _ in
        Color.clear
      }
      .pdf.overlayRelease { _ in }
    }
  }

  _ = NamespaceSurfaceView().body
}

@MainActor
private final class IntBindingBox {
  var value: Int

  init(_ value: Int) {
    self.value = value
  }
}

@MainActor
private final class StringBindingBox {
  var value: String

  init(_ value: String) {
    self.value = value
  }
}

@MainActor
private final class OptionalIntBindingBox {
  var value: Int?

  init(_ value: Int?) {
    self.value = value
  }
}

@MainActor
private final class SearchOptionsBindingBox {
  var value: PDFSearchOptions

  init(_ value: PDFSearchOptions) {
    self.value = value
  }
}

@MainActor
private final class SearchResultsBindingBox {
  var value: [PDFSearchHit]

  init(_ value: [PDFSearchHit]) {
    self.value = value
  }
}

@MainActor
private func makeBinding(for box: IntBindingBox) -> Binding<Int> {
  Binding(
    get: { box.value },
    set: { box.value = $0 }
  )
}

@MainActor
private func makeBinding(for box: StringBindingBox) -> Binding<String> {
  Binding(
    get: { box.value },
    set: { box.value = $0 }
  )
}

@MainActor
private func makeBinding(for box: OptionalIntBindingBox) -> Binding<Int?> {
  Binding(
    get: { box.value },
    set: { box.value = $0 }
  )
}

@MainActor
private func makeBinding(for box: SearchOptionsBindingBox) -> Binding<PDFSearchOptions> {
  Binding(
    get: { box.value },
    set: { box.value = $0 }
  )
}

@MainActor
private func makeBinding(for box: SearchResultsBindingBox) -> Binding<[PDFSearchHit]> {
  Binding(
    get: { box.value },
    set: { box.value = $0 }
  )
}

@MainActor
private func currentPageIndex(in pdfView: PDFView) -> Int {
  guard let document = pdfView.document, let currentPage = pdfView.currentPage else {
    return 0
  }

  return max(0, document.index(for: currentPage))
}

private func fixturePDFURL() throws -> URL {
  let testFileURL = URL(fileURLWithPath: #filePath)
  let repositoryRoot = testFileURL
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
  let fixtureURL = repositoryRoot.appendingPathComponent("drawingwithquartz2d.pdf")

  guard FileManager.default.fileExists(atPath: fixtureURL.path) else {
    throw NSError(
      domain: "PDFTests",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Fixture file not found at \(fixtureURL.path)"]
    )
  }

  return fixtureURL
}
