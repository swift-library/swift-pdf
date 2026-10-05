import PDFKit
import SwiftUI
import Testing

@testable import PDF

extension PDFTests {
  @Suite("PageOverlay")
  @MainActor
  final class PageOverlay: PDFKitSuite {
    @Test
    func absentOverlayCallbacksLeavePDFKitProviderDisabled() {
      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PageOverlayProviderTrackingPDFView()

      coordinator.updatePageOverlayViewCallbacks(PDFPageOverlayViewCallbacks())
      coordinator.configurePageOverlayViewProvider(in: pdfView)

      #expect(pdfView.pageOverlayViewProvider == nil)
      #expect(pdfView.providerSetCount == 0)
    }

    @Test
    func providerWiringIsIdempotentAndDisablesExactlyOnce() {
      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PageOverlayProviderTrackingPDFView()

      coordinator.updatePageOverlayViewCallbacks(
        PDFPageOverlayViewCallbacks(
          contentProvider: { _ in AnyView(Color.red) }
        )
      )
      coordinator.configurePageOverlayViewProvider(in: pdfView)
      let enabledSetCount = pdfView.providerSetCount

      coordinator.configurePageOverlayViewProvider(in: pdfView)

      #expect(pdfView.pageOverlayViewProvider === coordinator)
      #expect(enabledSetCount == 1)
      #expect(pdfView.providerSetCount == enabledSetCount)

      coordinator.updatePageOverlayViewCallbacks(PDFPageOverlayViewCallbacks())
      coordinator.configurePageOverlayViewProvider(in: pdfView)

      #expect(pdfView.pageOverlayViewProvider == nil)
      #expect(pdfView.providerSetCount == enabledSetCount + 1)
    }

    @Test
    func overlayCallbackRefreshDoesNotSynchronouslyInvokeContentProvider() async throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      let page = try #require(document.page(at: 0))

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PDFView()

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: nil,
        pageCountBinding: nil
      )

      coordinator.updatePageOverlayViewCallbacks(
        PDFPageOverlayViewCallbacks(
          contentProvider: { _ in AnyView(Color.red) }
        )
      )
      #expect(createOverlayView(using: coordinator, in: pdfView, for: page))

      var providerCallCount = 0
      coordinator.updatePageOverlayViewCallbacks(
        PDFPageOverlayViewCallbacks(
          contentProvider: { _ in
            providerCallCount += 1
            return AnyView(Color.blue)
          }
        )
      )

      #expect(providerCallCount == 0)
      await flushMainActorTasks()
      #expect(providerCallCount == 1)
    }

    @Test
    func disablingOverlayCallbacksClearsOverlayHostsAndPreventsFurtherOverlayCreation() throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      let page = try #require(document.page(at: 0))

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PDFView()

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: nil,
        pageCountBinding: nil
      )

      var releasedPages: [ObjectIdentifier] = []
      coordinator.updatePageOverlayViewCallbacks(
        PDFPageOverlayViewCallbacks(
          contentProvider: { _ in AnyView(Color.red) },
          release: { releasedPages.append(ObjectIdentifier($0)) }
        )
      )

      #expect(createOverlayView(using: coordinator, in: pdfView, for: page))
      coordinator.updatePageOverlayViewCallbacks(PDFPageOverlayViewCallbacks())
      #expect(!createOverlayView(using: coordinator, in: pdfView, for: page))
      #expect(releasedPages == [ObjectIdentifier(page)])
    }

    @Test
    func coordinatorDetachClearsOverlayHostsAndReleasesPagesOnce() throws {
      let document = try #require(PDFDocument(url: fixturePDFURL()))
      let page = try #require(document.page(at: 0))

      let coordinator = PDFViewContainer.Coordinator()
      let pdfView = PDFView()

      bindCoordinator(
        coordinator,
        pdfView: pdfView,
        initialSource: .document(document),
        currentPageBinding: nil,
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
  }
}

@MainActor
private final class PageOverlayProviderTrackingPDFView: PDFView {
  private(set) var providerSetCount = 0

  override weak var pageOverlayViewProvider: (any PDFPageOverlayViewProvider)? {
    didSet { providerSetCount += 1 }
  }
}
