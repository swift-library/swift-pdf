// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import CoreGraphics
import CoreText
import Foundation

/// A generated document with enough pages and text to try navigation, search and overlays.
enum SampleDocument {
  static func data(pageCount: Int = 12) -> Data {
    let data = NSMutableData()
    var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
    guard
      let consumer = CGDataConsumer(data: data as CFMutableData),
      let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
    else {
      return Data()
    }
    let title = CTFontCreateWithName("Helvetica-Bold" as CFString, 28, nil)
    let body = CTFontCreateWithName("Helvetica" as CFString, 15, nil)
    for index in 0..<pageCount {
      context.beginPDFPage(nil)
      draw("Chapter \(index + 1)", font: title, at: CGPoint(x: 72, y: 700), in: context)
      let paragraphs = [
        "This page belongs to a generated sample document.",
        "Search for \"swift\" or \"page\" to step through matches.",
        "Turn on overlays to place SwiftUI content above every page.",
        "Swift code can drive the viewer through PDFViewProxy.",
      ]
      for (offset, line) in paragraphs.enumerated() {
        draw(line, font: body, at: CGPoint(x: 72, y: 650 - CGFloat(offset) * 24), in: context)
      }
      context.endPDFPage()
    }
    context.closePDF()
    return data as Data
  }

  private static func draw(_ string: String, font: CTFont, at point: CGPoint, in context: CGContext) {
    let text = NSAttributedString(
      string: string,
      attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]
    )
    context.textPosition = point
    CTLineDraw(CTLineCreateWithAttributedString(text), context)
  }
}
