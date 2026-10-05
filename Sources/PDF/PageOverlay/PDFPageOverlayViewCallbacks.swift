import PDFKit

@MainActor
struct PDFPageOverlayViewCallbacks {
  var contentProvider: PDFPageOverlayViewContentProvider?
  var release: PDFPageOverlayViewRelease?

  init(
    contentProvider: PDFPageOverlayViewContentProvider? = nil,
    release: PDFPageOverlayViewRelease? = nil
  ) {
    self.contentProvider = contentProvider
    self.release = release
  }
}
