// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import Foundation
import SwiftUI

@MainActor
extension PDFViewBase where Base: View {
  /// Reads the query from a binding and refreshes matches when it changes.
  /// Leading and trailing whitespace is trimmed; an empty query clears matches.
  /// Search updates do not navigate automatically.
  public func searchQuery(_ query: Binding<String>) -> some View {
    base.environment(\.searchQueryBinding, query)
  }

  /// Reports the selected zero-based match index, or `nil`; writes do not select a match.
  /// Use the reader proxy to navigate among results.
  public func searchResultIndex(_ index: Binding<Int?>) -> some View {
    base.environment(\.searchResultIndexBinding, index)
  }

  /// Reports the number of current matches asynchronously; the binding is output only.
  public func searchResultCount(_ count: Binding<Int>) -> some View {
    base.environment(\.searchResultCountBinding, count)
  }

  /// Reads PDFKit string-comparison options and reruns the search when they change.
  public func searchOptions(_ options: Binding<NSString.CompareOptions>) -> some View {
    base.environment(\.searchOptionsBinding, options)
  }

  /// Reports snapshots of the current matches asynchronously; the binding is output only.
  public func searchResults(_ results: Binding<[PDFSearchResult]>) -> some View {
    base.environment(\.searchResultsBinding, results)
  }
}
