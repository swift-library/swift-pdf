import SwiftUI

@MainActor
struct PDFPageBindings {
  var pageIndex: Binding<Int>?
  var pageCount: Binding<Int>?

  init(pageIndex: Binding<Int>? = nil, pageCount: Binding<Int>? = nil) {
    self.pageIndex = pageIndex
    self.pageCount = pageCount
  }
}
