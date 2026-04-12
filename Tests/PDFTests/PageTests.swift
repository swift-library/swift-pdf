import PDFKit
import Testing

@testable import PDF

extension PDFTests {
  @Suite("Page")
  @MainActor
  final class Page: PDFKitSuite {
    @Test
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
    func pendingExternalPageNavigationIsNotOverwrittenByIntermediateRebind() throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      #expect(document.pageCount > 2)

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = NonAdvancingNavigationPDFView()

      let pageIndexBox = IntBindingBox(0)
      let pageCountBox = IntBindingBox(0)

      bindCoordinator(coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        pageIndexBinding: makeBinding(for: pageIndexBox),
        pageCountBinding: makeBinding(for: pageCountBox)
      )

      pageIndexBox.value = 2
      bindCoordinator(coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        pageIndexBinding: makeBinding(for: pageIndexBox),
        pageCountBinding: makeBinding(for: pageCountBox)
      )

      #expect(pageIndexBox.value == 2)
      #expect(pdfView.goToDestinationCallCount == 1)

      bindCoordinator(coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        pageIndexBinding: makeBinding(for: pageIndexBox),
        pageCountBinding: makeBinding(for: pageCountBox)
      )

      #expect(pageIndexBox.value == 2)
    }
  }
}

@MainActor
private final class NonAdvancingNavigationPDFView: PDFView {
  var goToDestinationCallCount = 0

  override func goToNextPage(_ sender: Any?) {}

  override func goToPreviousPage(_ sender: Any?) {}

  override func go(to destination: PDFDestination) {
    goToDestinationCallCount += 1
  }
}
