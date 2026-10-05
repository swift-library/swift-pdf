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

      let currentPageBox = TrackingIntBindingBox(0)
      let pageCountBox = IntBindingBox(0)

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: makeBinding(for: currentPageBox),
        pageCountBinding: makeBinding(for: pageCountBox)
      )

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: makeBinding(for: currentPageBox),
        pageCountBinding: makeBinding(for: pageCountBox)
      )

      let baselineSetCount = currentPageBox.setCount
      pdfView.goToNextPage(nil)
      NotificationCenter.default.post(
        name: Notification.Name.PDFViewPageChanged,
        object: pdfView
      )

      #expect(currentPageBox.value == 1)
      #expect(currentPageBox.setCount == baselineSetCount + 1)
    }

    @Test
    func detachStopsNotificationDrivenPageAndScalePropagation() throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      #expect(document.pageCount > 1)

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PDFView()

      let currentPageBox = TrackingIntBindingBox(0)
      let pageCountBox = IntBindingBox(0)
      let scaleFactorBox = IntBindingBox(0)

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: makeBinding(for: currentPageBox),
        pageCountBinding: makeBinding(for: pageCountBox),
        scaleFactorBinding: Binding(
          get: { CGFloat(scaleFactorBox.value) },
          set: { scaleFactorBox.value = Int($0) }
        )
      )

      let pageSnapshot = currentPageBox.value
      let pageSetCountSnapshot = currentPageBox.setCount
      let scaleSnapshot = scaleFactorBox.value

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

      #expect(currentPageBox.value == pageSnapshot)
      #expect(currentPageBox.setCount == pageSetCountSnapshot)
      #expect(scaleFactorBox.value == scaleSnapshot)
    }

    @Test
    func mountedDocumentSessionChangeRefreshesOwnersWhenSourceDedupeDoesNotReload() async throws {
      let populatedDocument = try #require(PDFDocument(url: fixturePDFURL()))
      let emptyDocument = PDFDocument()

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = NonDispatchingPDFView()

      let currentPageBox = IntBindingBox(0)
      let pageCountBox = IntBindingBox(0)
      let queryBox = StringBindingBox("the")
      let searchResultIndexBox = OptionalIntBindingBox(nil)
      let resultCountBox = IntBindingBox(0)
      let optionsBox = SearchOptionsBindingBox([.caseInsensitive])
      let resultsBox = SearchResultsBindingBox([])

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(populatedDocument),
        currentPageBinding: makeBinding(for: currentPageBox),
        pageCountBinding: makeBinding(for: pageCountBox),
        searchQueryBinding: makeBinding(for: queryBox),
        searchResultIndexBinding: makeBinding(for: searchResultIndexBox),
        searchResultCountBinding: makeBinding(for: resultCountBox),
        searchOptionsBinding: makeBinding(for: optionsBox),
        searchResultsBinding: makeBinding(for: resultsBox)
      )
      await flushMainActorTasks()

      #expect(resultCountBox.value > 0)
      #expect(pageCountBox.value == populatedDocument.pageCount)
      #expect(searchResultIndexBox.value == nil)

      pdfView.document = emptyDocument
      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(populatedDocument),
        currentPageBinding: makeBinding(for: currentPageBox),
        pageCountBinding: makeBinding(for: pageCountBox),
        searchQueryBinding: makeBinding(for: queryBox),
        searchResultIndexBinding: makeBinding(for: searchResultIndexBox),
        searchResultCountBinding: makeBinding(for: resultCountBox),
        searchOptionsBinding: makeBinding(for: optionsBox),
        searchResultsBinding: makeBinding(for: resultsBox)
      )
      await flushMainActorTasks()

      #expect(pdfView.document === emptyDocument)
      #expect(pageCountBox.value == 0)
      #expect(currentPageBox.value == 0)
      #expect(resultCountBox.value == 0)
      #expect(searchResultIndexBox.value == nil)
      #expect(resultsBox.value == [])
    }

    @Test
    func documentLoadPublishesPageBindingsBeforeSearchBindings() async throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      let emptyDocument = PDFDocument()

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = NonDispatchingPDFView()

      var currentPageValue = 0
      var pageCountValue = 0
      var queryValue = "the"
      var searchResultIndexValue: Int? = nil
      var resultCountValue = 0
      var optionsValue: NSString.CompareOptions = [.caseInsensitive]
      var resultsValue: [PDFSearchResult] = []
      var events: [String] = []

      let currentPageBinding = Binding(
        get: { currentPageValue },
        set: {
          currentPageValue = $0
          events.append("currentPage")
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
      let searchResultIndexBinding = Binding(
        get: { searchResultIndexValue },
        set: {
          searchResultIndexValue = $0
          events.append("searchResultIndex")
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

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(emptyDocument),
        currentPageBinding: currentPageBinding,
        pageCountBinding: pageCountBinding,
        searchQueryBinding: queryBinding,
        searchResultIndexBinding: searchResultIndexBinding,
        searchResultCountBinding: resultCountBinding,
        searchOptionsBinding: optionsBinding,
        searchResultsBinding: resultsBinding
      )

      events.removeAll()
      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: currentPageBinding,
        pageCountBinding: pageCountBinding,
        searchQueryBinding: queryBinding,
        searchResultIndexBinding: searchResultIndexBinding,
        searchResultCountBinding: resultCountBinding,
        searchOptionsBinding: optionsBinding,
        searchResultsBinding: resultsBinding
      )
      await flushMainActorTasks()

      let firstSearchEventIndex = try #require(events.firstIndex { $0.hasPrefix("search") })
      #expect(events.first == "pageCount")
      #expect(events[..<firstSearchEventIndex].contains("pageCount"))
      #expect(resultCountValue > 0)
      #expect(searchResultIndexValue == nil)
    }

    @Test
    func sameViewDocumentReplacementPublishesPageBeforeSearchAndReleasesOverlay() async throws {
      let populatedDocument = try #require(PDFDocument(url: fixturePDFURL()))
      #expect(populatedDocument.pageCount > 1)
      let emptyDocument = PDFDocument()
      let page = try #require(populatedDocument.page(at: 0))

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PDFView()
      let proxy = makeProxy()

      var currentPageValue = 0
      var pageCountValue = 0
      var queryValue = "the"
      var searchResultIndexValue: Int? = nil
      var resultCountValue = 0
      var optionsValue: NSString.CompareOptions = [.caseInsensitive]
      var resultsValue: [PDFSearchResult] = []
      var events: [String] = []

      let currentPageBinding = Binding(
        get: { currentPageValue },
        set: {
          currentPageValue = $0
          events.append("currentPage")
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
      let searchResultIndexBinding = Binding(
        get: { searchResultIndexValue },
        set: {
          searchResultIndexValue = $0
          events.append("searchResultIndex")
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

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(populatedDocument),
        currentPageBinding: currentPageBinding,
        pageCountBinding: pageCountBinding,
        searchQueryBinding: queryBinding,
        searchResultIndexBinding: searchResultIndexBinding,
        searchResultCountBinding: resultCountBinding,
        searchOptionsBinding: optionsBinding,
        searchResultsBinding: resultsBinding,
        proxy: proxy
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

      proxy.goToNextPage()
      NotificationCenter.default.post(name: .PDFViewPageChanged, object: pdfView)
      #expect(currentPageValue == 1)
      drainRunLoop()

      events.removeAll()
      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(emptyDocument),
        currentPageBinding: currentPageBinding,
        pageCountBinding: pageCountBinding,
        searchQueryBinding: queryBinding,
        searchResultIndexBinding: searchResultIndexBinding,
        searchResultCountBinding: resultCountBinding,
        searchOptionsBinding: optionsBinding,
        searchResultsBinding: resultsBinding,
        proxy: proxy
      )
      await flushMainActorTasks()

      #expect(released == [ObjectIdentifier(page)])
      #expect(pageCountValue == 0)
      #expect(currentPageValue == 0)
      #expect(resultCountValue == 0)
      #expect(searchResultIndexValue == nil)
      #expect(resultsValue == [])

      let firstSearchEventIndex = try #require(events.firstIndex { $0.hasPrefix("search") })
      #expect(events.contains("overlayRelease"))
      #expect(events[..<firstSearchEventIndex].contains("pageCount"))
      #expect(events[..<firstSearchEventIndex].contains("currentPage"))
    }

    @Test
    func nextMainActorTurnPublicationDefersBindingsAndPreservesOwnerOrder() async throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      let secondPage = try #require(document.page(at: 1))
      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = NonDispatchingPDFView()

      var currentPageValue = 0
      var pageCountValue = 0
      var queryValue = "the"
      var searchResultIndexValue: Int? = nil
      var resultCountValue = 0
      var optionsValue: NSString.CompareOptions = [.caseInsensitive]
      var resultsValue: [PDFSearchResult] = []
      var events: [String] = []

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: Binding(
          get: { currentPageValue },
          set: {
            currentPageValue = $0
            events.append("currentPage")
          }
        ),
        pageCountBinding: Binding(
          get: { pageCountValue },
          set: {
            pageCountValue = $0
            events.append("pageCount")
          }
        ),
        searchQueryBinding: Binding(
          get: { queryValue },
          set: { queryValue = $0 }
        ),
        searchResultIndexBinding: Binding(
          get: { searchResultIndexValue },
          set: {
            searchResultIndexValue = $0
            events.append("searchResultIndex")
          }
        ),
        searchResultCountBinding: Binding(
          get: { resultCountValue },
          set: {
            resultCountValue = $0
            events.append("searchResultCount")
          }
        ),
        searchOptionsBinding: Binding(
          get: { optionsValue },
          set: { optionsValue = $0 }
        ),
        searchResultsBinding: Binding(
          get: { resultsValue },
          set: {
            resultsValue = $0
            events.append("searchResults")
          }
        ),
        bindingPublicationTiming: .nextMainActorTurn
      )

      #expect(events.isEmpty)
      #expect(pageCountValue == 0)
      #expect(resultCountValue == 0)

      await flushMainActorTasks()
      await flushMainActorTasks()

      let firstSearchEventIndex = try #require(events.firstIndex { $0.hasPrefix("search") })
      #expect(events.first == "pageCount")
      #expect(events[..<firstSearchEventIndex].contains("pageCount"))
      #expect(pageCountValue == document.pageCount)
      #expect(resultCountValue > 0)

      events.removeAll()
      pdfView.go(to: secondPage)
      NotificationCenter.default.post(name: .PDFViewPageChanged, object: pdfView)

      #expect(currentPageValue == 0)
      #expect(events.isEmpty)

      await flushMainActorTasks()

      #expect(currentPageValue == 1)
      #expect(events.contains("currentPage"))
    }

    @Test
    func detachCancelsNextMainActorTurnBindingPublication() async throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PDFView()
      let pageCountBox = IntBindingBox(0)
      let resultCountBox = IntBindingBox(0)
      let queryBox = StringBindingBox("the")

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: nil,
        pageCountBinding: makeBinding(for: pageCountBox),
        searchQueryBinding: makeBinding(for: queryBox),
        searchResultCountBinding: makeBinding(for: resultCountBox),
        bindingPublicationTiming: .nextMainActorTurn
      )
      coordinator.detach()

      await flushMainActorTasks()

      #expect(pageCountBox.value == 0)
      #expect(resultCountBox.value == 0)
    }

  }
}
