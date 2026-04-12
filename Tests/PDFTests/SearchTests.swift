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
    func searchBindingsPublishMatchesAndSupportSelectionControl() async throws {
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
      await flushMainActorTasks()
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
      await flushMainActorTasks()
      #expect(selectionBox.value == max(0, resultCountBox.value - 1))
      if let selectedIndex = selectionBox.value, resultsBox.value.indices.contains(selectedIndex) {
        #expect(currentPageIndex(in: pdfView) == resultsBox.value[selectedIndex].pageIndex)
      }
    }

    @Test
    func searchQueryRefreshMovesPageBindingToFirstSearchMatch() async throws {
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
      await flushMainActorTasks()
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
      await flushMainActorTasks()

      let selectedIndex = try #require(selectionBox.value)
      #expect(resultsBox.value.indices.contains(selectedIndex))
      #expect(pageCountBox.value == document.pageCount)
      #expect(pageIndexBox.value == resultsBox.value[selectedIndex].pageIndex)
      #expect(pageIndexBox.value > 0)
    }

    @Test
    func searchOptionsChangesTriggerRecomputationWithoutChangingQuery() async throws {
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
      await flushMainActorTasks()

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
      await flushMainActorTasks()

      #expect(resultCountBox.value == 0)
      #expect(selectionBox.value == nil)
      #expect(resultsBox.value == [])
    }

    @Test
    func clearingSearchQueryResetsSearchBindings() async throws {
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
      await flushMainActorTasks()

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
      await flushMainActorTasks()

      #expect(resultCountBox.value == 0)
      #expect(selectionBox.value == nil)
      #expect(resultsBox.value == [])
    }

    @Test
    func searchBindingPublicationDedupesWhenStateIsUnchanged() async throws {
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
      await flushMainActorTasks()

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
      await flushMainActorTasks()

      #expect(selectionSetCount == selectionSetCountAfterFirstBind)
      #expect(resultCountSetCount == resultCountSetCountAfterFirstBind)
      #expect(resultsSetCount == resultsSetCountAfterFirstBind)
    }

    @Test
    func pageChangesDoNotResetSearchBindings() async throws {
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
      await flushMainActorTasks()

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
      await flushMainActorTasks()

      #expect(queryBox.value == "Quartz")
      #expect(resultCountBox.value == initialResultCount)
      #expect(selectionBox.value == initialSelection)
    }
  }
}
