import Foundation
import SwiftUI

@MainActor
extension PDFViewBase where Base: View {
  public func searchQuery(_ query: Binding<String>) -> some View {
    base.environment(\.searchQueryBinding, query)
  }

  public func searchResultIndex(_ index: Binding<Int?>) -> some View {
    base.environment(\.searchResultIndexBinding, index)
  }

  public func searchResultCount(_ count: Binding<Int>) -> some View {
    base.environment(\.searchResultCountBinding, count)
  }

  public func searchOptions(_ options: Binding<NSString.CompareOptions>) -> some View {
    base.environment(\.searchOptionsBinding, options)
  }

  public func searchResults(_ results: Binding<[PDFSearchResult]>) -> some View {
    base.environment(\.searchResultsBinding, results)
  }
}
