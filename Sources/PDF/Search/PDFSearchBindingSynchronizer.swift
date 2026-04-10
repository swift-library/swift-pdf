import PDFKit
import SwiftUI

@MainActor
final class PDFSearchBindingSynchronizer {
  private var lastAppliedExternalSelection: Int?
  private var lastPublishedSelection: Int?

  func reset() {
    lastAppliedExternalSelection = nil
    lastPublishedSelection = nil
  }

  func sync(
    on pdfView: PDFView?,
    runtime: PDFSearchRuntime,
    queryBinding: Binding<String>?,
    selectionBinding: Binding<Int?>?,
    resultCountBinding: Binding<Int>?,
    optionsBinding: Binding<PDFSearchOptions>?,
    resultsBinding: Binding<[PDFSearchHit]>?
  ) {
    let query = runtime.normalizedQuery(from: queryBinding?.wrappedValue)
    let options = optionsBinding?.wrappedValue ?? .default
    let didRefresh = runtime.refreshIfNeeded(on: pdfView, query: query, options: options)

    if didRefresh {
      lastAppliedExternalSelection = nil
      lastPublishedSelection = nil
    } else {
      applyExternalSelectionIfNeeded(
        on: pdfView,
        runtime: runtime,
        selectionBinding: selectionBinding
      )
    }

    publish(
      runtime: runtime,
      selectionBinding: selectionBinding,
      resultCountBinding: resultCountBinding,
      resultsBinding: resultsBinding
    )
  }

  private func applyExternalSelectionIfNeeded(
    on pdfView: PDFView?,
    runtime: PDFSearchRuntime,
    selectionBinding: Binding<Int?>?
  ) {
    guard let selectionBinding else {
      return
    }

    let snapshot = runtime.snapshot
    guard snapshot.resultCount > 0 else {
      write(selectionBinding, value: nil)
      lastAppliedExternalSelection = nil
      return
    }

    guard let requestedSelection = selectionBinding.wrappedValue else {
      if let currentSelection = snapshot.currentSelectionIndex {
        lastAppliedExternalSelection = currentSelection
        return
      }

      let focused = runtime.focusFirstResultIfNeeded(on: pdfView)
      lastAppliedExternalSelection = focused
      return
    }

    guard let clampedSelection = runtime.clampedSelection(requestedSelection) else {
      write(selectionBinding, value: nil)
      lastAppliedExternalSelection = nil
      return
    }

    write(selectionBinding, value: clampedSelection)

    if lastAppliedExternalSelection == clampedSelection
      && lastPublishedSelection == clampedSelection
    {
      return
    }

    if snapshot.currentSelectionIndex == clampedSelection {
      lastAppliedExternalSelection = clampedSelection
      return
    }

    let focused = runtime.focusSelection(at: clampedSelection, on: pdfView)
    lastAppliedExternalSelection = focused
  }

  private func publish(
    runtime: PDFSearchRuntime,
    selectionBinding: Binding<Int?>?,
    resultCountBinding: Binding<Int>?,
    resultsBinding: Binding<[PDFSearchHit]>?
  ) {
    let snapshot = runtime.snapshot
    write(resultCountBinding, value: snapshot.resultCount)
    write(selectionBinding, value: snapshot.currentSelectionIndex)
    write(resultsBinding, value: snapshot.hits)
    lastPublishedSelection = snapshot.currentSelectionIndex
  }

  private func write<T: Equatable>(_ binding: Binding<T>?, value: T) {
    guard let binding, binding.wrappedValue != value else {
      return
    }

    // Write immediately for deterministic coordinator behavior, then write again on the next
    // main-actor turn so SwiftUI preview/update passes can observe the external binding update.
    binding.wrappedValue = value
    Task { @MainActor in
      if binding.wrappedValue != value {
        binding.wrappedValue = value
      }
    }
  }
}
