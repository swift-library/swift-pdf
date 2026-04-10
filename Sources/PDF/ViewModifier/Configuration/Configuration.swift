import CoreGraphics
import PDFKit
import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

public struct PDFPageMargins: Sendable, Equatable {
  public var top: CGFloat
  public var left: CGFloat
  public var bottom: CGFloat
  public var right: CGFloat

  public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
    self.top = top
    self.left = left
    self.bottom = bottom
    self.right = right
  }
}

public struct PDFViewConfiguration {
  public static var `default`: PDFViewConfiguration {
    PDFViewConfiguration()
  }

  public var displayMode: PDFDisplayMode
  public var displayDirection: PDFDisplayDirection
  public var isInMarkupMode: Bool

  public var autoScales: Bool?
  public var backgroundColor: Color?
  public var displaysAsBook: Bool?
  public var displaysPageBreaks: Bool?
  public var displaysRTL: Bool?
  public var minScaleFactor: CGFloat?
  public var maxScaleFactor: CGFloat?
  public var pageBreakMargins: PDFPageMargins?
  public var pageShadowsEnabled: Bool?

  public init(
    displayMode: PDFDisplayMode = .singlePage,
    displayDirection: PDFDisplayDirection = .horizontal,
    isInMarkupMode: Bool = false,
    autoScales: Bool? = nil,
    backgroundColor: Color? = .white,
    displaysAsBook: Bool? = nil,
    displaysPageBreaks: Bool? = nil,
    displaysRTL: Bool? = nil,
    minScaleFactor: CGFloat? = nil,
    maxScaleFactor: CGFloat? = nil,
    pageBreakMargins: PDFPageMargins? = nil,
    pageShadowsEnabled: Bool? = nil
  ) {
    self.displayMode = displayMode
    self.displayDirection = displayDirection
    self.isInMarkupMode = isInMarkupMode
    self.autoScales = autoScales
    self.backgroundColor = backgroundColor
    self.displaysAsBook = displaysAsBook
    self.displaysPageBreaks = displaysPageBreaks
    self.displaysRTL = displaysRTL
    self.minScaleFactor = minScaleFactor
    self.maxScaleFactor = maxScaleFactor
    self.pageBreakMargins = pageBreakMargins
    self.pageShadowsEnabled = pageShadowsEnabled
  }
}

extension PDFViewConfiguration {
  @MainActor
  func apply(to pdfView: PDFView) {
    pdfView.displayMode = displayMode
    pdfView.displayDirection = displayDirection

    #if canImport(UIKit)
      pdfView.isInMarkupMode = isInMarkupMode
    #endif

    if let autoScales {
      pdfView.autoScales = autoScales
    }

    if let backgroundColor {
      #if canImport(UIKit)
        pdfView.backgroundColor = UIColor(backgroundColor)
      #elseif canImport(AppKit)
        pdfView.backgroundColor = NSColor(backgroundColor)
      #endif
    }

    if let displaysAsBook {
      pdfView.displaysAsBook = displaysAsBook
    }

    if let displaysPageBreaks {
      pdfView.displaysPageBreaks = displaysPageBreaks
    }

    if let displaysRTL {
      pdfView.displaysRTL = displaysRTL
    }

    if let minScaleFactor {
      pdfView.minScaleFactor = minScaleFactor
    }

    if let maxScaleFactor {
      pdfView.maxScaleFactor = maxScaleFactor
    }

    if let pageBreakMargins {
      #if canImport(UIKit)
        pdfView.pageBreakMargins = UIEdgeInsets(
          top: pageBreakMargins.top,
          left: pageBreakMargins.left,
          bottom: pageBreakMargins.bottom,
          right: pageBreakMargins.right
        )
      #elseif canImport(AppKit)
        pdfView.pageBreakMargins = NSEdgeInsets(
          top: pageBreakMargins.top,
          left: pageBreakMargins.left,
          bottom: pageBreakMargins.bottom,
          right: pageBreakMargins.right
        )
      #endif
    }

    if let pageShadowsEnabled {
      pdfView.pageShadowsEnabled = pageShadowsEnabled
    }
  }
}

public final class PDFViewConfigurationBuilder {
  private var configuration: PDFViewConfiguration

  public static func builder() -> PDFViewConfigurationBuilder {
    PDFViewConfigurationBuilder()
  }

  public init(base: PDFViewConfiguration = .default) {
    self.configuration = base
  }

  public func displayMode(_ displayMode: PDFDisplayMode) -> Self {
    configuration.displayMode = displayMode
    return self
  }

  public func displayDirection(_ displayDirection: PDFDisplayDirection) -> Self {
    configuration.displayDirection = displayDirection
    return self
  }

  public func isInMarkupMode(_ isInMarkupMode: Bool) -> Self {
    configuration.isInMarkupMode = isInMarkupMode
    return self
  }

  public func autoScales(_ autoScales: Bool) -> Self {
    configuration.autoScales = autoScales
    return self
  }

  public func backgroundColor(_ backgroundColor: Color) -> Self {
    configuration.backgroundColor = backgroundColor
    return self
  }

  public func displaysAsBook(_ displaysAsBook: Bool) -> Self {
    configuration.displaysAsBook = displaysAsBook
    return self
  }

  public func displaysPageBreaks(_ displaysPageBreaks: Bool) -> Self {
    configuration.displaysPageBreaks = displaysPageBreaks
    return self
  }

  public func displaysRTL(_ displaysRTL: Bool) -> Self {
    configuration.displaysRTL = displaysRTL
    return self
  }

  public func minScaleFactor(_ minScaleFactor: CGFloat) -> Self {
    configuration.minScaleFactor = minScaleFactor
    return self
  }

  public func maxScaleFactor(_ maxScaleFactor: CGFloat) -> Self {
    configuration.maxScaleFactor = maxScaleFactor
    return self
  }

  public func pageBreakMargins(_ pageBreakMargins: PDFPageMargins) -> Self {
    configuration.pageBreakMargins = pageBreakMargins
    return self
  }

  #if canImport(UIKit)
    public func pageBreakMargins(_ pageBreakMargins: UIEdgeInsets) -> Self {
      configuration.pageBreakMargins = PDFPageMargins(
        top: pageBreakMargins.top,
        left: pageBreakMargins.left,
        bottom: pageBreakMargins.bottom,
        right: pageBreakMargins.right
      )
      return self
    }
  #elseif canImport(AppKit)
    public func pageBreakMargins(_ pageBreakMargins: NSEdgeInsets) -> Self {
      configuration.pageBreakMargins = PDFPageMargins(
        top: pageBreakMargins.top,
        left: pageBreakMargins.left,
        bottom: pageBreakMargins.bottom,
        right: pageBreakMargins.right
      )
      return self
    }
  #endif

  public func pageShadowsEnabled(_ pageShadowsEnabled: Bool) -> Self {
    configuration.pageShadowsEnabled = pageShadowsEnabled
    return self
  }

  public func build() -> PDFViewConfiguration {
    configuration
  }
}
