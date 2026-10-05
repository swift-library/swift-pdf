import PDFKit
import Testing

@testable import PDF

extension PDFTests {
  @Suite("Page")
  @MainActor
  final class Page: PDFKitSuite {
    @Test
    func proxyPageCommandsDriveNavigationAndPublishSettledState() throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      #expect(document.pageCount > 0)

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PDFView()
      let proxy = makeProxy()

      let currentPageBox = IntBindingBox(0)
      let pageCountBox = IntBindingBox(0)

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: makeBinding(for: currentPageBox),
        pageCountBinding: makeBinding(for: pageCountBox),
        proxy: proxy
      )

      #expect(pdfView.document === document)
      #expect(pageCountBox.value == document.pageCount)
      #expect(currentPageBox.value == 0)

      proxy.goToPage(at: document.pageCount + 99)
      NotificationCenter.default.post(name: .PDFViewPageChanged, object: pdfView)

      let lastPageIndex = max(0, document.pageCount - 1)
      #expect(currentPageBox.value == lastPageIndex)
      #expect(currentPageIndex(in: pdfView) == lastPageIndex)

      proxy.goToPage(at: -123)
      NotificationCenter.default.post(name: .PDFViewPageChanged, object: pdfView)

      #expect(currentPageBox.value == 0)
      #expect(currentPageIndex(in: pdfView) == 0)
    }

    @Test
    func internalPageChangesPublishBackIntoCurrentPageBinding() throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      #expect(document.pageCount > 1)

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PDFView()

      let currentPageBox = IntBindingBox(0)
      let pageCountBox = IntBindingBox(0)

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: makeBinding(for: currentPageBox),
        pageCountBinding: makeBinding(for: pageCountBox)
      )

      #expect(currentPageBox.value == 0)
      #expect(pageCountBox.value == document.pageCount)

      pdfView.goToNextPage(nil)
      NotificationCenter.default.post(name: .PDFViewPageChanged, object: pdfView)

      #expect(currentPageBox.value == 1)
    }

    @Test
    func goToPageUsesDirectPageTargetDispatch() throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      #expect(document.pageCount > 2)

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = TrackingNavigationPDFView()
      let proxy = makeProxy()

      let currentPageBox = IntBindingBox(0)
      let pageCountBox = IntBindingBox(0)

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: makeBinding(for: currentPageBox),
        pageCountBinding: makeBinding(for: pageCountBox),
        proxy: proxy
      )

      // UIKit's PDFView navigates to the first page itself when it receives a document.
      let baseline = pdfView.goToPageCallCount

      proxy.goToPage(at: 1)

      #expect(pdfView.goToPageCallCount == baseline + 1)
      #expect(pdfView.goToPreviousPageCallCount == 0)
      #expect(pdfView.goToDestinationCallCount == 0)
      #expect(pdfView.goToNextPageCallCount == 0)

      proxy.goToPage(at: 0)

      #expect(pdfView.goToPageCallCount == baseline + 2)
      #expect(pdfView.goToDestinationCallCount == 0)
      #expect(pdfView.goToPreviousPageCallCount == 0)

      proxy.goToPage(at: 2)

      #expect(pdfView.goToPageCallCount == baseline + 3)
      #expect(pdfView.goToDestinationCallCount == 0)
    }

    @Test
    func currentPageBindingWritesDoNotActAsCommands() throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      #expect(document.pageCount > 2)

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = NonAdvancingNavigationPDFView()

      let currentPageBox = IntBindingBox(0)
      let pageCountBox = IntBindingBox(0)

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: makeBinding(for: currentPageBox),
        pageCountBinding: makeBinding(for: pageCountBox)
      )

      currentPageBox.value = 2
      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: makeBinding(for: currentPageBox),
        pageCountBinding: makeBinding(for: pageCountBox)
      )

      #expect(currentPageBox.value == 0)
      #expect(pdfView.goToDestinationCallCount == 0)
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
