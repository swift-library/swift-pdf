import Foundation
import SwiftUI

@MainActor
struct PDFSearchBindings {
  var query: Binding<String>?
  var selection: Binding<Int?>?
  var resultCount: Binding<Int>?
  var options: Binding<NSString.CompareOptions>?
  var results: Binding<[PDFSearchResult]>?

  init(
    query: Binding<String>? = nil,
    selection: Binding<Int?>? = nil,
    resultCount: Binding<Int>? = nil,
    options: Binding<NSString.CompareOptions>? = nil,
    results: Binding<[PDFSearchResult]>? = nil
  ) {
    self.query = query
    self.selection = selection
    self.resultCount = resultCount
    self.options = options
    self.results = results
  }
}
