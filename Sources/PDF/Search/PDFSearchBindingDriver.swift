import Foundation
import SwiftUI

@MainActor
final class PDFSearchBindingDriver {
  private var publishWorkItem: DispatchWorkItem?

  func publish(
    _ state: PDFSearchEngine.State,
    searchBindings: PDFSearchBindings
  ) {
    publishWorkItem?.cancel()

    let publishWorkItem = DispatchWorkItem {
      searchBindings.searchResultCount?.setIfChanged(state.searchResultCount)
      searchBindings.searchResultIndex?.setIfChanged(state.searchResultIndex)
      searchBindings.results?.setIfChanged(state.results)
    }

    self.publishWorkItem = publishWorkItem
    DispatchQueue.main.async(execute: publishWorkItem)
  }

  func reset() {
    publishWorkItem?.cancel()
    publishWorkItem = nil
  }
}
