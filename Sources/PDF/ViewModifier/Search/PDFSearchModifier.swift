import SwiftUI

@MainActor
extension PDFViewBase where Base: View {
  public func searchQuery(_ query: Binding<String>) -> some View {
    base.environment(\.searchQueryBinding, query)
  }

  public func searchSelection(_ selection: Binding<Int?>) -> some View {
    base.environment(\.searchSelectionBinding, selection)
  }

  public func searchResultCount(_ count: Binding<Int>) -> some View {
    base.environment(\.searchResultCountBinding, count)
  }

  public func searchOptions(_ options: Binding<PDFSearchOptions>) -> some View {
    base.environment(\.searchOptionsBinding, options)
  }

  public func searchResults(_ results: Binding<[PDFSearchHit]>) -> some View {
    base.environment(\.searchResultsBinding, results)
  }
}
