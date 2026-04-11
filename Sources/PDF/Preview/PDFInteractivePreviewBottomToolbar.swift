#if DEBUG && canImport(SwiftUI) && PDF_INTERNAL_PREVIEW
  import SwiftUI

  @MainActor
  struct PDFInteractivePreviewBottomToolbar: View {
    @Binding var searchQuery: String
    let searchResultCount: Int
    let searchSummary: String
    let canClearSearch: Bool
    let onPreviousSearch: () -> Void
    let onNextSearch: () -> Void
    let onClearSearch: () -> Void

    var body: some View {
      VStack(spacing: 8) {
        HStack(spacing: 8) {
          TextField("Search in PDF", text: $searchQuery)
            .textFieldStyle(.roundedBorder)

          Button("Prev", action: onPreviousSearch)
            .disabled(searchResultCount == 0)

          Button("Next", action: onNextSearch)
            .disabled(searchResultCount == 0)

          Button("Clear", action: onClearSearch)
            .disabled(!canClearSearch)
        }
        .buttonStyle(.bordered)

        HStack {
          Text(searchSummary)
            .font(.footnote.monospacedDigit())
            .foregroundStyle(.secondary)
          Spacer()
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 10)
      .background(.ultraThinMaterial)
    }
  }
#endif
