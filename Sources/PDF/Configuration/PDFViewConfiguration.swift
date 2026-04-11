import PDFKit

struct PDFViewConfiguration: Equatable {
  var displayMode: PDFDisplayMode
  var displayDirection: PDFDisplayDirection
  var autoScales: Bool
  var isInMarkupMode: Bool

  init(
    displayMode: PDFDisplayMode? = nil,
    displayDirection: PDFDisplayDirection? = nil,
    autoScales: Bool? = nil,
    isInMarkupMode: Bool? = nil
  ) {
    self.displayMode = displayMode ?? .singlePage
    self.displayDirection = displayDirection ?? .horizontal
    self.autoScales = autoScales ?? false
    self.isInMarkupMode = isInMarkupMode ?? false
  }
}
