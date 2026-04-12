import Foundation
import SwiftUI

@MainActor
struct PDFSearchBindings {
  var query: Binding<String>?
  var searchResultIndex: Binding<Int?>?
  var searchResultCount: Binding<Int>?
  var options: Binding<NSString.CompareOptions>?
  var results: Binding<[PDFSearchResult]>?

  init(
    query: Binding<String>? = nil,
    searchResultIndex: Binding<Int?>? = nil,
    searchResultCount: Binding<Int>? = nil,
    options: Binding<NSString.CompareOptions>? = nil,
    results: Binding<[PDFSearchResult]>? = nil
  ) {
    self.query = query
    self.searchResultIndex = searchResultIndex
    self.searchResultCount = searchResultCount
    self.options = options
    self.results = results
  }
}
