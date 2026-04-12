import Foundation
import PDFKit
import SwiftUI
import Testing

@testable import PDF

extension PDFTests {
  @Suite("Bridge")
  @MainActor
  final class Bridge: PDFKitSuite {
    @Test
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
    func mountedDocumentSessionChangeRefreshesOwnersWhenSourceDedupeDoesNotReload() async throws {
      let populatedDocument = try #require(PDFDocument(url: fixturePDFURL()))
      let emptyDocument = PDFDocument()

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = NonDispatchingPDFView()

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
      await flushMainActorTasks()

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
      await flushMainActorTasks()

      #expect(pdfView.document === emptyDocument)
      #expect(pageCountBox.value == 0)
      #expect(pageIndexBox.value == 0)
      #expect(resultCountBox.value == 0)
      #expect(selectionBox.value == nil)
      #expect(resultsBox.value == [])
    }

    @Test
    func documentLoadPublishesPageBindingsBeforeSearchBindings() async throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      let emptyDocument = PDFDocument()

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = NonDispatchingPDFView()

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
      await flushMainActorTasks()

      let firstSearchEventIndex = try #require(events.firstIndex { $0.hasPrefix("search") })
      #expect(events.first == "pageCount")
      #expect(events[..<firstSearchEventIndex].contains("pageCount"))
      #expect(resultCountValue > 0)
      #expect(selectionValue != nil)
    }

    @Test
    func sameViewDocumentReplacementPublishesPageBeforeSearchAndReleasesOverlay() async throws {
      let populatedDocument = try #require(PDFDocument(url: fixturePDFURL()))
      #expect(populatedDocument.pageCount > 1)
      let emptyDocument = PDFDocument()
      let page = try #require(populatedDocument.page(at: 0))

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = NonDispatchingPDFView()

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
      await flushMainActorTasks()

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
      drainRunLoop()

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
      await flushMainActorTasks()

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
  }
}
