import SwiftUI

extension EnvironmentValues {
  @Entry
  var searchQueryBinding: Binding<String>? = nil

  @Entry
  var searchSelectionBinding: Binding<Int?>? = nil

  @Entry
  var searchResultCountBinding: Binding<Int>? = nil

  @Entry
  var searchOptionsBinding: Binding<PDFSearchOptions>? = nil

  @Entry
  var searchResultsBinding: Binding<[PDFSearchHit]>? = nil
}
