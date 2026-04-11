import PDFKit

extension PDFView {
  @MainActor
  func configure(using configuration: PDFViewConfiguration) {
    displayMode = configuration.displayMode
    displayDirection = configuration.displayDirection
    autoScales = configuration.autoScales
    isInMarkupMode = configuration.isInMarkupMode
  }
}
