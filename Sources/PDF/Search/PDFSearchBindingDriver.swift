import SwiftUI

@MainActor
final class PDFSearchBindingDriver {
  func performFind(
    engine: PDFSearchEngine,
    searchBindings: PDFSearchBindings
  ) -> PDFSearchEngine.Decision {
    let query = searchBindings.query?.wrappedValue ?? ""
    let options = searchBindings.options?.wrappedValue ?? []
    let selectionIndex = searchBindings.selection?.wrappedValue

    let decision = engine.decide(
      query: query,
      options: options,
      selectionIndex: selectionIndex
    )
    publish(decision.publication, searchBindings: searchBindings)
    return decision
  }

  private func publish(
    _ publication: PDFSearchEngine.Decision.Publication,
    searchBindings: PDFSearchBindings
  ) {
    write(searchBindings.resultCount, value: publication.resultCount)
    write(searchBindings.selection, value: publication.selectionIndex)
    write(searchBindings.results, value: publication.results)
  }

  private func write<T: Equatable>(_ binding: Binding<T>?, value: T) {
    guard let binding, binding.wrappedValue != value else { return }
    binding.wrappedValue = value
  }
}
