import Foundation
import PDFKit
import SwiftUI
import Testing

@testable import PDF

extension PDFTests {
  @Suite("Search")
  @MainActor
  final class Search: PDFKitSuite {
    @Test
    func searchBindingsPublishMatchesWithoutAutomaticNavigation() async throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      #expect(document.pageCount > 0)

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PDFView()

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
        initialSource: .document(document),
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
      #expect(searchResultIndexBox.value == nil)
      #expect(resultsBox.value.count == resultCountBox.value)
      #expect(currentPageBox.value == 0)
      #expect(currentPageIndex(in: pdfView) == 0)

      for (offset, hit) in resultsBox.value.enumerated() {
        #expect(hit.index == offset)
      }
    }

    @Test
    func proxySearchCommandsNavigateAndPublishSearchResultIndex() async throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      #expect(document.pageCount > 1)

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PDFView()
      let proxy = makeProxy()

      let currentPageBox = IntBindingBox(0)
      let pageCountBox = IntBindingBox(0)
      let queryBox = StringBindingBox("apple")
      let searchResultIndexBox = OptionalIntBindingBox(nil)
      let resultCountBox = IntBindingBox(0)
      let optionsBox = SearchOptionsBindingBox([.caseInsensitive])
      let resultsBox = SearchResultsBindingBox([])

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: makeBinding(for: currentPageBox),
        pageCountBinding: makeBinding(for: pageCountBox),
        searchQueryBinding: makeBinding(for: queryBox),
        searchResultIndexBinding: makeBinding(for: searchResultIndexBox),
        searchResultCountBinding: makeBinding(for: resultCountBox),
        searchOptionsBinding: makeBinding(for: optionsBox),
        searchResultsBinding: makeBinding(for: resultsBox),
        proxy: proxy
      )
      await flushMainActorTasks()

      #expect(resultCountBox.value > 0)
      #expect(searchResultIndexBox.value == nil)

      proxy.goToSearchResult(at: resultCountBox.value + 99)
      await flushMainActorTasks()

      let selectedIndex = max(0, resultCountBox.value - 1)
      #expect(searchResultIndexBox.value == selectedIndex)
      #expect(resultsBox.value.indices.contains(selectedIndex))
      #expect(currentPageBox.value == resultsBox.value[selectedIndex].pageIndex)

      proxy.goToPreviousSearchResult()
      await flushMainActorTasks()

      let previousIndex = ((selectedIndex - 1) + resultCountBox.value) % resultCountBox.value
      #expect(searchResultIndexBox.value == previousIndex)
      #expect(currentPageBox.value == resultsBox.value[previousIndex].pageIndex)
    }

    @Test
    func searchOptionsChangesTriggerRecomputationWithoutChangingQuery() async throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PDFView()

      let queryBox = StringBindingBox("apple")
      let searchResultIndexBox = OptionalIntBindingBox(nil)
      let resultCountBox = IntBindingBox(0)
      let optionsBox = SearchOptionsBindingBox([.caseInsensitive])
      let resultsBox = SearchResultsBindingBox([])

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: nil,
        pageCountBinding: nil,
        searchQueryBinding: makeBinding(for: queryBox),
        searchResultIndexBinding: makeBinding(for: searchResultIndexBox),
        searchResultCountBinding: makeBinding(for: resultCountBox),
        searchOptionsBinding: makeBinding(for: optionsBox),
        searchResultsBinding: makeBinding(for: resultsBox)
      )
      await flushMainActorTasks()

      #expect(resultCountBox.value > 0)
      #expect(resultsBox.value.count == resultCountBox.value)

      optionsBox.value = []
      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: nil,
        pageCountBinding: nil,
        searchQueryBinding: makeBinding(for: queryBox),
        searchResultIndexBinding: makeBinding(for: searchResultIndexBox),
        searchResultCountBinding: makeBinding(for: resultCountBox),
        searchOptionsBinding: makeBinding(for: optionsBox),
        searchResultsBinding: makeBinding(for: resultsBox)
      )
      await flushMainActorTasks()

      #expect(resultCountBox.value == 0)
      #expect(searchResultIndexBox.value == nil)
      #expect(resultsBox.value == [])
    }

    @Test
    func clearingSearchQueryResetsSearchBindings() async throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PDFView()

      let queryBox = StringBindingBox("fixture")
      let searchResultIndexBox = OptionalIntBindingBox(nil)
      let resultCountBox = IntBindingBox(0)
      let optionsBox = SearchOptionsBindingBox([.caseInsensitive])
      let resultsBox = SearchResultsBindingBox([])

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: nil,
        pageCountBinding: nil,
        searchQueryBinding: makeBinding(for: queryBox),
        searchResultIndexBinding: makeBinding(for: searchResultIndexBox),
        searchResultCountBinding: makeBinding(for: resultCountBox),
        searchOptionsBinding: makeBinding(for: optionsBox),
        searchResultsBinding: makeBinding(for: resultsBox)
      )
      await flushMainActorTasks()

      queryBox.value = ""
      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: nil,
        pageCountBinding: nil,
        searchQueryBinding: makeBinding(for: queryBox),
        searchResultIndexBinding: makeBinding(for: searchResultIndexBox),
        searchResultCountBinding: makeBinding(for: resultCountBox),
        searchOptionsBinding: makeBinding(for: optionsBox),
        searchResultsBinding: makeBinding(for: resultsBox)
      )
      await flushMainActorTasks()

      #expect(resultCountBox.value == 0)
      #expect(searchResultIndexBox.value == nil)
      #expect(resultsBox.value == [])
    }

    @Test
    func searchBindingPublicationDedupesWhenStateIsUnchanged() async throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PDFView()

      var queryValue = "the"
      var searchResultIndexValue: Int? = nil
      var resultCountValue = 0
      var optionsValue: NSString.CompareOptions = [.caseInsensitive]
      var resultsValue: [PDFSearchResult] = []

      var searchResultIndexSetCount = 0
      var resultCountSetCount = 0
      var resultsSetCount = 0

      let queryBinding = Binding(
        get: { queryValue },
        set: { queryValue = $0 }
      )
      let searchResultIndexBinding = Binding(
        get: { searchResultIndexValue },
        set: {
          searchResultIndexValue = $0
          searchResultIndexSetCount += 1
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
        currentPageBinding: nil,
        pageCountBinding: nil,
        searchQueryBinding: queryBinding,
        searchResultIndexBinding: searchResultIndexBinding,
        searchResultCountBinding: resultCountBinding,
        searchOptionsBinding: optionsBinding,
        searchResultsBinding: resultsBinding
      )
      await flushMainActorTasks()

      #expect(resultCountValue > 0)
      let searchResultIndexSetCountAfterFirstBind = searchResultIndexSetCount
      let resultCountSetCountAfterFirstBind = resultCountSetCount
      let resultsSetCountAfterFirstBind = resultsSetCount

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: nil,
        pageCountBinding: nil,
        searchQueryBinding: queryBinding,
        searchResultIndexBinding: searchResultIndexBinding,
        searchResultCountBinding: resultCountBinding,
        searchOptionsBinding: optionsBinding,
        searchResultsBinding: resultsBinding
      )
      await flushMainActorTasks()

      #expect(searchResultIndexSetCount == searchResultIndexSetCountAfterFirstBind)
      #expect(resultCountSetCount == resultCountSetCountAfterFirstBind)
      #expect(resultsSetCount == resultsSetCountAfterFirstBind)
    }

    @Test
    func pageChangesDoNotResetSearchBindings() async throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      #expect(document.pageCount > 1)

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PDFView()

      let currentPageBox = IntBindingBox(0)
      let pageCountBox = IntBindingBox(0)
      let queryBox = StringBindingBox("fixture")
      let searchResultIndexBox = OptionalIntBindingBox(nil)
      let resultCountBox = IntBindingBox(0)

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: makeBinding(for: currentPageBox),
        pageCountBinding: makeBinding(for: pageCountBox),
        searchQueryBinding: makeBinding(for: queryBox),
        searchResultIndexBinding: makeBinding(for: searchResultIndexBox),
        searchResultCountBinding: makeBinding(for: resultCountBox)
      )
      await flushMainActorTasks()

      let initialResultCount = resultCountBox.value
      let initialSearchResultIndex = searchResultIndexBox.value
      #expect(initialResultCount > 0)

      pdfView.goToNextPage(nil)
      NotificationCenter.default.post(name: .PDFViewPageChanged, object: pdfView)
      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: makeBinding(for: currentPageBox),
        pageCountBinding: makeBinding(for: pageCountBox),
        searchQueryBinding: makeBinding(for: queryBox),
        searchResultIndexBinding: makeBinding(for: searchResultIndexBox),
        searchResultCountBinding: makeBinding(for: resultCountBox)
      )
      await flushMainActorTasks()

      #expect(queryBox.value == "fixture")
      #expect(resultCountBox.value == initialResultCount)
      #expect(searchResultIndexBox.value == initialSearchResultIndex)
    }
  }
}
