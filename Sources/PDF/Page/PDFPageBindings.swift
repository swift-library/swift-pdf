import CoreGraphics
import SwiftUI

@MainActor
struct PDFPageBindings {
  var currentPage: Binding<Int>?
  var pageCount: Binding<Int>?
  var scaleFactor: Binding<CGFloat>?

  init(
    currentPage: Binding<Int>? = nil,
    pageCount: Binding<Int>? = nil,
    scaleFactor: Binding<CGFloat>? = nil
  ) {
    self.currentPage = currentPage
    self.pageCount = pageCount
    self.scaleFactor = scaleFactor
  }
}
