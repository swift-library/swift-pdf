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
  let source = PDFDocument.Representation.document(document)

  #expect(source.resolveDocument() === document)
}

@Test
func documentSourceDataCaseBuildsReadableDocument() throws {
  let fixtureData = try Data(contentsOf: fixturePDFURL())
  let source = PDFDocument.Representation.data(fixtureData)

  let document = try #require(source.resolveDocument())
  #expect(document.pageCount > 0)
}

@Test
func documentSourceFileURLCaseBuildsReadableDocument() throws {
  let source = PDFDocument.Representation.fileURL(try fixturePDFURL())

  let document = try #require(source.resolveDocument())
  #expect(document.pageCount > 0)
}

@Test
@MainActor
func repeatedLoadWithSameDataSourceDoesNotRemountDocument() throws {
  let fixtureData = try Data(contentsOf: fixturePDFURL())
  let source = PDFDocument.Representation.data(fixtureData)
  let loader = PDFDocument.CachedLoader()
  let pdfView = PDFView()

  #expect(loader.load(representation: source, into: pdfView) == .documentChanged)
  let firstDocument = try #require(pdfView.document)

  #expect(loader.load(representation: source, into: pdfView) == .unchanged)
  #expect(pdfView.document === firstDocument)
}

@Test
func viewerConfigurationDefaultsMatchSupportedModifierDefaults() {
  let configuration = PDFViewConfiguration()

  #expect(configuration.displayMode == .singlePage)
  #expect(configuration.displayDirection == .horizontal)
  #expect(configuration.autoScales == false)
  #expect(configuration.isInMarkupMode == false)
}

@Test
@MainActor
func configureUsingAppliesResolvedConfigurationToPDFView() {
  let pdfView = PDFView()
  let configuration = PDFViewConfiguration(
    displayMode: .twoUpContinuous,
    displayDirection: .vertical,
    autoScales: true,
    isInMarkupMode: true
  )

  pdfView.configure(using: configuration)

  #expect(pdfView.displayMode == .twoUpContinuous)
  #expect(pdfView.displayDirection == .vertical)
  #expect(pdfView.autoScales == true)
  #expect(pdfView.isInMarkupMode == true)
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

  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  #expect(pdfView.document === document)
  #expect(pageCountBox.value == document.pageCount)
  #expect(pageIndexBox.value == 0)

  pageIndexBox.value = document.pageCount + 99
  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  let lastPageIndex = max(0, document.pageCount - 1)
  #expect(pageIndexBox.value == lastPageIndex)
  #expect(currentPageIndex(in: pdfView) == lastPageIndex)

  pageIndexBox.value = -123
  bindCoordinator(coordinator,
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

  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  #expect(pageIndexBox.value == 0)
  #expect(pageCountBox.value == document.pageCount)

  pdfView.goToNextPage(nil)
  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  #expect(pageIndexBox.value == 1)
}

@Test
@MainActor
func adjacentPageBindingPrefersStepNavigationWithDestinationFallback() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))
  #expect(document.pageCount > 2)

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = TrackingNavigationPDFView()

  let pageIndexBox = IntBindingBox(0)
  let pageCountBox = IntBindingBox(0)

  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  pageIndexBox.value = 1
  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  #expect(pdfView.goToNextPageCallCount == 1)
  #expect(pdfView.goToPreviousPageCallCount == 0)
  #expect(pdfView.goToDestinationCallCount == 0)

  pageIndexBox.value = 0
  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  #expect(pdfView.goToPreviousPageCallCount == 1)
  #expect(pdfView.goToDestinationCallCount == 0)

  pageIndexBox.value = 2
  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  #expect(pdfView.goToDestinationCallCount == 1)
}

@Test
@MainActor
func rebindingSameViewDoesNotDuplicateObservableNotificationEffects() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))
  #expect(document.pageCount > 1)

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  let pageIndexBox = TrackingIntBindingBox(0)
  let pageCountBox = IntBindingBox(0)

  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  let baselineSetCount = pageIndexBox.setCount
  pdfView.goToNextPage(nil)
  NotificationCenter.default.post(
    name: Notification.Name.PDFViewPageChanged,
    object: pdfView
  )

  #expect(pageIndexBox.value == 1)
  #expect(pageIndexBox.setCount == baselineSetCount + 1)
}

@Test
@MainActor
func detachStopsNotificationDrivenPageAndScalePropagation() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))
  #expect(document.pageCount > 1)

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  let pageIndexBox = TrackingIntBindingBox(0)
  let pageCountBox = IntBindingBox(0)

  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox)
  )

  let pageIndexSnapshot = pageIndexBox.value
  let pageSetCountSnapshot = pageIndexBox.setCount

  coordinator.detach()

  pdfView.goToNextPage(nil)
  NotificationCenter.default.post(
    name: Notification.Name.PDFViewPageChanged,
    object: pdfView
  )
  NotificationCenter.default.post(
    name: Notification.Name.PDFViewScaleChanged,
    object: pdfView
  )

  #expect(pageIndexBox.value == pageIndexSnapshot)
  #expect(pageIndexBox.setCount == pageSetCountSnapshot)
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
  let optionsBox = SearchOptionsBindingBox([.caseInsensitive])
  let resultsBox = SearchResultsBindingBox([])

  bindCoordinator(coordinator,
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
  bindCoordinator(coordinator,
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
func searchQueryRefreshMovesPageBindingToFirstSearchMatch() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))
  #expect(document.pageCount > 1)

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  let pageIndexBox = IntBindingBox(0)
  let pageCountBox = IntBindingBox(0)
  let queryBox = StringBindingBox("apple")
  let selectionBox = OptionalIntBindingBox(nil)
  let resultCountBox = IntBindingBox(0)
  let optionsBox = SearchOptionsBindingBox([.caseInsensitive])
  let resultsBox = SearchResultsBindingBox([])

  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox),
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox),
    searchOptionsBinding: makeBinding(for: optionsBox),
    searchResultsBinding: makeBinding(for: resultsBox)
  )
  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox),
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox),
    searchOptionsBinding: makeBinding(for: optionsBox),
    searchResultsBinding: makeBinding(for: resultsBox)
  )

  let selectedIndex = try #require(selectionBox.value)
  #expect(resultsBox.value.indices.contains(selectedIndex))
  #expect(pageCountBox.value == document.pageCount)
  #expect(pageIndexBox.value == resultsBox.value[selectedIndex].pageIndex)
  #expect(pageIndexBox.value > 0)
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
  let optionsBox = SearchOptionsBindingBox([.caseInsensitive])
  let resultsBox = SearchResultsBindingBox([])

  bindCoordinator(coordinator,
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

  optionsBox.value = []
  bindCoordinator(coordinator,
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
  let optionsBox = SearchOptionsBindingBox([.caseInsensitive])
  let resultsBox = SearchResultsBindingBox([])

  bindCoordinator(coordinator,
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
  bindCoordinator(coordinator,
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
func mountedDocumentSessionChangeRefreshesOwnersWhenSourceDedupeDoesNotReload() throws {
  let populatedDocument = try #require(PDFDocument(url: fixturePDFURL()))
  let emptyDocument = PDFDocument()

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  let pageIndexBox = IntBindingBox(0)
  let pageCountBox = IntBindingBox(0)
  let queryBox = StringBindingBox("the")
  let selectionBox = OptionalIntBindingBox(nil)
  let resultCountBox = IntBindingBox(0)
  let optionsBox = SearchOptionsBindingBox([.caseInsensitive])
  let resultsBox = SearchResultsBindingBox([])

  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(populatedDocument),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox),
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox),
    searchOptionsBinding: makeBinding(for: optionsBox),
    searchResultsBinding: makeBinding(for: resultsBox)
  )
  #expect(resultCountBox.value > 0)
  #expect(pageCountBox.value == populatedDocument.pageCount)

  pdfView.document = emptyDocument
  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(populatedDocument),
    pageIndexBinding: makeBinding(for: pageIndexBox),
    pageCountBinding: makeBinding(for: pageCountBox),
    searchQueryBinding: makeBinding(for: queryBox),
    searchSelectionBinding: makeBinding(for: selectionBox),
    searchResultCountBinding: makeBinding(for: resultCountBox),
    searchOptionsBinding: makeBinding(for: optionsBox),
    searchResultsBinding: makeBinding(for: resultsBox)
  )

  #expect(pdfView.document === emptyDocument)
  #expect(pageCountBox.value == 0)
  #expect(pageIndexBox.value == 0)
  #expect(resultCountBox.value == 0)
  #expect(selectionBox.value == nil)
  #expect(resultsBox.value == [])
}

@Test
@MainActor
func documentLoadPublishesPageBindingsBeforeSearchBindings() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))
  let emptyDocument = PDFDocument()

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  var pageIndexValue = 0
  var pageCountValue = 0
  var queryValue = "the"
  var selectionValue: Int? = nil
  var resultCountValue = 0
  var optionsValue: NSString.CompareOptions = [.caseInsensitive]
  var resultsValue: [PDFSearchResult] = []
  var events: [String] = []

  let pageIndexBinding = Binding(
    get: { pageIndexValue },
    set: {
      pageIndexValue = $0
      events.append("pageIndex")
    }
  )
  let pageCountBinding = Binding(
    get: { pageCountValue },
    set: {
      pageCountValue = $0
      events.append("pageCount")
    }
  )
  let queryBinding = Binding(
    get: { queryValue },
    set: { queryValue = $0 }
  )
  let selectionBinding = Binding(
    get: { selectionValue },
    set: {
      selectionValue = $0
      events.append("searchSelection")
    }
  )
  let resultCountBinding = Binding(
    get: { resultCountValue },
    set: {
      resultCountValue = $0
      events.append("searchResultCount")
    }
  )
  let optionsBinding = Binding(
    get: { optionsValue },
    set: { optionsValue = $0 }
  )
  let resultsBinding = Binding(
    get: { resultsValue },
    set: {
      resultsValue = $0
      events.append("searchResults")
    }
  )

  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(emptyDocument),
    pageIndexBinding: pageIndexBinding,
    pageCountBinding: pageCountBinding,
    searchQueryBinding: queryBinding,
    searchSelectionBinding: selectionBinding,
    searchResultCountBinding: resultCountBinding,
    searchOptionsBinding: optionsBinding,
    searchResultsBinding: resultsBinding
  )

  events.removeAll()
  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: pageIndexBinding,
    pageCountBinding: pageCountBinding,
    searchQueryBinding: queryBinding,
    searchSelectionBinding: selectionBinding,
    searchResultCountBinding: resultCountBinding,
    searchOptionsBinding: optionsBinding,
    searchResultsBinding: resultsBinding
  )

  let firstSearchEventIndex = try #require(events.firstIndex { $0.hasPrefix("search") })
  #expect(events.first == "pageCount")
  #expect(events[..<firstSearchEventIndex].contains("pageCount"))
  #expect(resultCountValue > 0)
  #expect(selectionValue != nil)
}

@Test
@MainActor
func sameViewDocumentReplacementPublishesPageBeforeSearchAndReleasesOverlay() throws {
  let populatedDocument = try #require(PDFDocument(url: fixturePDFURL()))
  #expect(populatedDocument.pageCount > 1)
  let emptyDocument = PDFDocument()
  let page = try #require(populatedDocument.page(at: 0))

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  var pageIndexValue = 0
  var pageCountValue = 0
  var queryValue = "the"
  var selectionValue: Int? = nil
  var resultCountValue = 0
  var optionsValue: NSString.CompareOptions = [.caseInsensitive]
  var resultsValue: [PDFSearchResult] = []
  var events: [String] = []

  let pageIndexBinding = Binding(
    get: { pageIndexValue },
    set: {
      pageIndexValue = $0
      events.append("pageIndex")
    }
  )
  let pageCountBinding = Binding(
    get: { pageCountValue },
    set: {
      pageCountValue = $0
      events.append("pageCount")
    }
  )
  let queryBinding = Binding(
    get: { queryValue },
    set: { queryValue = $0 }
  )
  let selectionBinding = Binding(
    get: { selectionValue },
    set: {
      selectionValue = $0
      events.append("searchSelection")
    }
  )
  let resultCountBinding = Binding(
    get: { resultCountValue },
    set: {
      resultCountValue = $0
      events.append("searchResultCount")
    }
  )
  let optionsBinding = Binding(
    get: { optionsValue },
    set: { optionsValue = $0 }
  )
  let resultsBinding = Binding(
    get: { resultsValue },
    set: {
      resultsValue = $0
      events.append("searchResults")
    }
  )

  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(populatedDocument),
    pageIndexBinding: pageIndexBinding,
    pageCountBinding: pageCountBinding,
    searchQueryBinding: queryBinding,
    searchSelectionBinding: selectionBinding,
    searchResultCountBinding: resultCountBinding,
    searchOptionsBinding: optionsBinding,
    searchResultsBinding: resultsBinding
  )

  var released: [ObjectIdentifier] = []
  coordinator.updatePageOverlayViewCallbacks(
    PDFPageOverlayViewCallbacks(
      contentProvider: { _ in AnyView(Color.red) },
      release: {
        released.append(ObjectIdentifier($0))
        events.append("overlayRelease")
      }
    )
  )
  #expect(createOverlayView(using: coordinator, in: pdfView, for: page))

  pageIndexValue = 1
  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(populatedDocument),
    pageIndexBinding: pageIndexBinding,
    pageCountBinding: pageCountBinding,
    searchQueryBinding: queryBinding,
    searchSelectionBinding: selectionBinding,
    searchResultCountBinding: resultCountBinding,
    searchOptionsBinding: optionsBinding,
    searchResultsBinding: resultsBinding
  )
  #expect(pageIndexValue == 1)

  events.removeAll()
  bindCoordinator(coordinator,
    pdfView: pdfView,
    initialSource: .document(emptyDocument),
    pageIndexBinding: pageIndexBinding,
    pageCountBinding: pageCountBinding,
    searchQueryBinding: queryBinding,
    searchSelectionBinding: selectionBinding,
    searchResultCountBinding: resultCountBinding,
    searchOptionsBinding: optionsBinding,
    searchResultsBinding: resultsBinding
  )

  #expect(released == [ObjectIdentifier(page)])
  #expect(pageCountValue == 0)
  #expect(pageIndexValue == 0)
  #expect(resultCountValue == 0)
  #expect(selectionValue == nil)
  #expect(resultsValue == [])

  let firstSearchEventIndex = try #require(events.firstIndex { $0.hasPrefix("search") })
  #expect(events.contains("overlayRelease"))
  #expect(events[..<firstSearchEventIndex].contains("pageCount"))
  #expect(events[..<firstSearchEventIndex].contains("pageIndex"))
}

@Test
@MainActor
func searchBindingPublicationDedupesWhenStateIsUnchanged() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  var queryValue = "the"
  var selectionValue: Int? = nil
  var resultCountValue = 0
  var optionsValue: NSString.CompareOptions = [.caseInsensitive]
  var resultsValue: [PDFSearchResult] = []

  var selectionSetCount = 0
  var resultCountSetCount = 0
  var resultsSetCount = 0

  let queryBinding = Binding(
    get: { queryValue },
    set: { queryValue = $0 }
  )
  let selectionBinding = Binding(
    get: { selectionValue },
    set: {
      selectionValue = $0
      selectionSetCount += 1
    }
  )
  let resultCountBinding = Binding(
    get: { resultCountValue },
    set: {
      resultCountValue = $0
      resultCountSetCount += 1
    }
  )
  let optionsBinding = Binding(
    get: { optionsValue },
    set: { optionsValue = $0 }
  )
  let resultsBinding = Binding(
    get: { resultsValue },
    set: {
      resultsValue = $0
      resultsSetCount += 1
    }
  )

  bindCoordinator(
    coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: nil,
    pageCountBinding: nil,
    searchQueryBinding: queryBinding,
    searchSelectionBinding: selectionBinding,
    searchResultCountBinding: resultCountBinding,
    searchOptionsBinding: optionsBinding,
    searchResultsBinding: resultsBinding
  )

  #expect(resultCountValue > 0)
  let selectionSetCountAfterFirstBind = selectionSetCount
  let resultCountSetCountAfterFirstBind = resultCountSetCount
  let resultsSetCountAfterFirstBind = resultsSetCount

  bindCoordinator(
    coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: nil,
    pageCountBinding: nil,
    searchQueryBinding: queryBinding,
    searchSelectionBinding: selectionBinding,
    searchResultCountBinding: resultCountBinding,
    searchOptionsBinding: optionsBinding,
    searchResultsBinding: resultsBinding
  )

  #expect(selectionSetCount == selectionSetCountAfterFirstBind)
  #expect(resultCountSetCount == resultCountSetCountAfterFirstBind)
  #expect(resultsSetCount == resultsSetCountAfterFirstBind)
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

  bindCoordinator(coordinator,
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
  bindCoordinator(coordinator,
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
func coordinatorDetachClearsOverlayHostsAndReleasesPagesOnce() throws {
  let document = try #require(PDFDocument(url: fixturePDFURL()))
  let page = try #require(document.page(at: 0))

  let coordinator = PDFViewContainer.Coordinator()
  let pdfView = PDFView()

  bindCoordinator(
    coordinator,
    pdfView: pdfView,
    initialSource: .document(document),
    pageIndexBinding: nil,
    pageCountBinding: nil
  )

  var released: [ObjectIdentifier] = []
  coordinator.updatePageOverlayViewCallbacks(
    PDFPageOverlayViewCallbacks(
      contentProvider: { _ in AnyView(Color.red) },
      release: { released.append(ObjectIdentifier($0)) }
    )
  )

  #expect(createOverlayView(using: coordinator, in: pdfView, for: page))
  coordinator.detach()
  endOverlayDisplay(using: coordinator, in: pdfView, for: page)

  #expect(released == [ObjectIdentifier(page)])
}

@MainActor
private func bindCoordinator(
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
private func createOverlayView(
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
private func endOverlayDisplay(
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
private final class IntBindingBox {
  var value: Int

  init(_ value: Int) {
    self.value = value
  }
}

@MainActor
private final class TrackingIntBindingBox {
  var value: Int
  var setCount: Int

  init(_ value: Int, setCount: Int = 0) {
    self.value = value
    self.setCount = setCount
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
  var value: NSString.CompareOptions

  init(_ value: NSString.CompareOptions) {
    self.value = value
  }
}

@MainActor
private final class SearchResultsBindingBox {
  var value: [PDFSearchResult]

  init(_ value: [PDFSearchResult]) {
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
private func makeBinding(for box: TrackingIntBindingBox) -> Binding<Int> {
  Binding(
    get: { box.value },
    set: {
      box.value = $0
      box.setCount += 1
    }
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
private func makeBinding(for box: SearchOptionsBindingBox) -> Binding<NSString.CompareOptions> {
  Binding(
    get: { box.value },
    set: { box.value = $0 }
  )
}

@MainActor
private func makeBinding(for box: SearchResultsBindingBox) -> Binding<[PDFSearchResult]> {
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

@MainActor
private final class TrackingNavigationPDFView: PDFView {
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

private func fixturePDFURL() throws -> URL {
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

private func repositoryRootURL() throws -> URL {
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
