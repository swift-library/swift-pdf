import PDFKit

@MainActor
struct PDFOverlayCallbacks {
  var contentProvider: PDFPageOverlayContentProvider
  var release: PDFPageOverlayRelease

  init(
    contentProvider: @escaping PDFPageOverlayContentProvider = { _ in nil },
    release: @escaping PDFPageOverlayRelease = { _ in }
  ) {
    self.contentProvider = contentProvider
    self.release = release
  }
}
