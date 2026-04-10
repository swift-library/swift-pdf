import PDFKit

struct PDFViewConfigurationResolver {
  func resolve(
    base: PDFViewConfiguration,
    displayMode: PDFDisplayMode?,
    displayDirection: PDFDisplayDirection?,
    autoScales: Bool?,
    isInMarkupMode: Bool?
  ) -> PDFViewConfiguration {
    var resolved = base

    if let displayMode {
      resolved.displayMode = displayMode
    }

    if let displayDirection {
      resolved.displayDirection = displayDirection
    }

    if let autoScales {
      resolved.autoScales = autoScales
    }

    if let isInMarkupMode {
      resolved.isInMarkupMode = isInMarkupMode
    }

    return resolved
  }
}
