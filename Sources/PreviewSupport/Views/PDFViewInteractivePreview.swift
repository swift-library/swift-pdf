#if DEBUG && canImport(SwiftUI)
  import PDF
  import PDFKit
  import SwiftUI

  @MainActor
  struct PDFViewInteractivePreview: View {
    @State private var overlayTelemetry = PreviewOverlayTelemetry()

    @State private var pageIndex: Int = 0
    @State private var pageCount: Int = 0
    @State private var pageInput: String = "1"
    @State private var searchQuery: String = ""
    @State private var searchSelection: Int? = nil
    @State private var searchResultCount: Int = 0
    @State private var isInMarkupMode: Bool = true
    @State private var overlayMode: PreviewOverlayMode = .interactive

    let source: PDFDocument.Representation

    private var currentPageNumber: Int {
      pageCount > 0 ? pageIndex + 1 : 0
    }

    private var pageSummary: String {
      guard pageCount > 0 else {
        return "Page -/-"
      }
      return "Page \(currentPageNumber)/\(pageCount)"
    }

    private var canGoToPreviousPage: Bool {
      pageCount > 0 && pageIndex > 0
    }

    private var canGoToNextPage: Bool {
      pageCount > 0 && pageIndex < pageCount - 1
    }

    private var overlaySummary: String {
      guard overlayMode != .off else {
        return "Overlay: off"
      }

      let activeCount = overlayTelemetry.activePages.count
      let lastTapped = overlayTelemetry.lastTappedPage ?? "-"
      return
        "Overlay P:\(overlayTelemetry.providedCount) R:\(overlayTelemetry.releasedCount) A:\(activeCount) T:\(overlayTelemetry.tapCount) Last:\(lastTapped)"
    }

    private var searchSummary: String {
      guard searchResultCount > 0, let searchSelection else {
        return "Matches: 0"
      }

      return "Matches: \(searchSelection + 1)/\(searchResultCount)"
    }

    @ViewBuilder
    private var documentBody: some View {
      let base = PDF(source: source)
        .pdf.displayMode(.singlePageContinuous)
        .pdf.displayDirection(.vertical)
        .pdf.isInMarkupMode(isInMarkupMode)
        .pdf.autoScales(true)
        .pdf.page($pageIndex)
        .pdf.pageCount($pageCount)
        .pdf.searchQuery($searchQuery)
        .pdf.searchSelection($searchSelection)
        .pdf.searchResultCount($searchResultCount)

      if overlayMode == .off {
        base
      } else {
        base
          .pdf.overlay { page in
            let pageKey = overlayKey(for: page)
            overlayTelemetry.noteProvided(pageKey)
            return makeOverlayContent(for: pageKey, mode: overlayMode)
          }
          .pdf.overlayRelease { page in
            overlayTelemetry.noteReleased(overlayKey(for: page))
          }
      }
    }

    var body: some View {
      documentBody
        .safeAreaInset(edge: .top) {
          topToolbar
        }
        .safeAreaInset(edge: .bottom) {
          bottomToolbar
        }
        .onChange(of: pageIndex) { _, _ in
          if pageCount > 0 {
            pageInput = "\(currentPageNumber)"
          }
        }
        .onChange(of: pageCount) { _, _ in
          if pageCount == 0 {
            pageInput = "1"
          } else {
            pageInput = "\(currentPageNumber)"
          }
        }
        .onChange(of: overlayMode) { _, _ in
          overlayTelemetry.reset()
        }
        .onChange(of: isInMarkupMode) { _, _ in
          overlayTelemetry.reset()
        }
        .frame(height: 600)
    }

    private var topToolbar: some View {
      VStack(spacing: 8) {
        HStack(spacing: 8) {
          Button {
            pageIndex = 0
          } label: {
            Label("First", systemImage: "backward.end.fill")
          }
          .disabled(!canGoToPreviousPage)

          Button {
            pageIndex = max(0, pageIndex - 1)
          } label: {
            Label("Prev", systemImage: "chevron.left")
          }
          .disabled(!canGoToPreviousPage)

          Button {
            pageIndex = min(max(pageCount - 1, 0), pageIndex + 1)
          } label: {
            Label("Next", systemImage: "chevron.right")
          }
          .disabled(!canGoToNextPage)

          Button {
            if pageCount > 0 {
              pageIndex = pageCount - 1
            }
          } label: {
            Label("Last", systemImage: "forward.end.fill")
          }
          .disabled(!canGoToNextPage)

          Spacer()

          TextField("Page", text: $pageInput)
            .textFieldStyle(.roundedBorder)
            .frame(width: 64)
            .onSubmit {
              jumpToPageFromInput()
            }

          Button("Go") {
            jumpToPageFromInput()
          }
          .disabled(pageCount == 0)
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

          Button("Reset Overlay") {
            overlayTelemetry.reset()
          }
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
          if overlayMode != .off && !isInMarkupMode {
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

    private var bottomToolbar: some View {
      VStack(spacing: 8) {
        HStack(spacing: 8) {
          TextField("Search in PDF", text: $searchQuery)
            .textFieldStyle(.roundedBorder)

          Button("Prev") {
            goToPreviousSearchResult()
          }
          .disabled(searchResultCount == 0)

          Button("Next") {
            goToNextSearchResult()
          }
          .disabled(searchResultCount == 0)

          Button("Clear") {
            searchQuery = ""
            searchSelection = nil
          }
          .disabled(searchResultCount == 0 && searchQuery.isEmpty)
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

    private func jumpToPageFromInput() {
      guard pageCount > 0,
        let pageNumber = Int(pageInput),
        (1...pageCount).contains(pageNumber)
      else {
        return
      }

      pageIndex = pageNumber - 1
    }

    private func goToPreviousSearchResult() {
      guard searchResultCount > 0 else {
        return
      }

      let currentIndex = searchSelection ?? 0
      searchSelection = (currentIndex - 1 + searchResultCount) % searchResultCount
    }

    private func goToNextSearchResult() {
      guard searchResultCount > 0 else {
        return
      }

      let currentIndex = searchSelection ?? -1
      searchSelection = (currentIndex + 1) % searchResultCount
    }

    private func overlayKey(for page: PDFPage) -> String {
      if let label = page.label, !label.isEmpty {
        return label
      }

      if let document = page.document {
        return "\(document.index(for: page) + 1)"
      }

      return "?"
    }

    @ViewBuilder
    private func makeOverlayContent(for pageKey: String, mode: PreviewOverlayMode) -> some View {
      switch mode {
      case .off:
        EmptyView()
      case .badge:
        Text("Page \(pageKey)")
          .font(.caption.monospaced().weight(.semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(Color.blue.opacity(0.78))
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .padding(12)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      case .interactive:
        Text("Tap \(pageKey)")
          .font(.caption.monospaced().weight(.semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 10)
          .padding(.vertical, 7)
          .background(Color.blue.opacity(0.78))
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .contentShape(RoundedRectangle(cornerRadius: 8))
          .onTapGesture {
            overlayTelemetry.noteTapped(pageKey)
          }
          .padding(12)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
    }
  }
#endif
