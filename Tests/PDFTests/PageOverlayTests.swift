import PDFKit
import SwiftUI
import Testing

@testable import PDF

extension PDFTests {
  @Suite("PageOverlay")
  @MainActor
  final class PageOverlay: PDFKitSuite {
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
        pageIndexBinding: nil,
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
        pageIndexBinding: nil,
        pageCountBinding: nil
      )

      coordinator.updatePageOverlayViewCallbacks(
        PDFPageOverlayViewCallbacks(
          contentProvider: { _ in AnyView(Color.red) }
        )
      )

      #expect(createOverlayView(using: coordinator, in: pdfView, for: page))
      coordinator.updatePageOverlayViewCallbacks(PDFPageOverlayViewCallbacks())
      #expect(!createOverlayView(using: coordinator, in: pdfView, for: page))
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
  }
}
