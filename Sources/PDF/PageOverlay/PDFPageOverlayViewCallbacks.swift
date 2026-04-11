import PDFKit

@MainActor
struct PDFPageOverlayViewCallbacks {
  var contentProvider: PDFPageOverlayViewContentProvider
  var release: PDFPageOverlayViewRelease

  init(
    contentProvider: @escaping PDFPageOverlayViewContentProvider = { _ in nil },
    release: @escaping PDFPageOverlayViewRelease = { _ in }
  ) {
    self.contentProvider = contentProvider
    self.release = release
  }
}
