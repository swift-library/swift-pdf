import SwiftUI

@MainActor
struct PDFSearchBindings {
  var query: Binding<String>?
  var selection: Binding<Int?>?
  var resultCount: Binding<Int>?
  var options: Binding<PDFSearchOptions>?
  var results: Binding<[PDFSearchHit]>?

  init(
    query: Binding<String>? = nil,
    selection: Binding<Int?>? = nil,
    resultCount: Binding<Int>? = nil,
    options: Binding<PDFSearchOptions>? = nil,
    results: Binding<[PDFSearchHit]>? = nil
  ) {
    self.query = query
    self.selection = selection
    self.resultCount = resultCount
    self.options = options
    self.results = results
  }
}
