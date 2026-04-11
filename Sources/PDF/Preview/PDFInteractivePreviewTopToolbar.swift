#if DEBUG && canImport(SwiftUI) && PDF_INTERNAL_PREVIEW
  import SwiftUI

  @MainActor
  struct PDFInteractivePreviewTopToolbar: View {
    let pageSummary: String
    let overlaySummary: String
    @Binding var pageInput: String
    let canGoToPreviousPage: Bool
    let canGoToNextPage: Bool
    let canJumpToPage: Bool
    @Binding var isInMarkupMode: Bool
    @Binding var overlayMode: PreviewOverlayMode
    let showMarkupWarning: Bool
    let onFirst: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onLast: () -> Void
    let onJumpToPage: () -> Void
    let onResetOverlayTelemetry: () -> Void

    var body: some View {
      VStack(spacing: 8) {
        HStack(spacing: 8) {
          Button(action: onFirst) {
            Label("First", systemImage: "backward.end.fill")
          }
          .disabled(!canGoToPreviousPage)

          Button(action: onPrevious) {
            Label("Prev", systemImage: "chevron.left")
          }
          .disabled(!canGoToPreviousPage)

          Button(action: onNext) {
            Label("Next", systemImage: "chevron.right")
          }
          .disabled(!canGoToNextPage)

          Button(action: onLast) {
            Label("Last", systemImage: "forward.end.fill")
          }
          .disabled(!canGoToNextPage)

          Spacer()

          TextField("Page", text: $pageInput)
            .textFieldStyle(.roundedBorder)
            .frame(width: 64)
            .onSubmit {
              onJumpToPage()
            }

          Button("Go", action: onJumpToPage)
            .disabled(!canJumpToPage)
        }
        .buttonStyle(.bordered)

        HStack(spacing: 12) {
          Text(pageSummary)
            .font(.footnote.monospacedDigit())

          Spacer()

          Toggle("Markup", isOn: $isInMarkupMode)
            .toggleStyle(.switch)
            .fixedSize()

          Picker("Overlay", selection: $overlayMode) {
            ForEach(PreviewOverlayMode.allCases) { mode in
              Text(mode.rawValue).tag(mode)
            }
          }
          .pickerStyle(.segmented)
          .frame(maxWidth: 260)

          Button("Reset Overlay", action: onResetOverlayTelemetry)
        }
        .font(.footnote)

        HStack {
          Text(overlaySummary)
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
          Spacer()
        }

        #if canImport(UIKit)
          if showMarkupWarning {
            HStack {
              Text("Overlay requires Markup on iOS/visionOS.")
                .font(.caption2)
                .foregroundStyle(.secondary)
              Spacer()
            }
          }
        #endif
      }
      .padding(.horizontal)
      .padding(.top, 8)
      .padding(.bottom, 10)
      .background(.ultraThinMaterial)
    }
  }
#endif
