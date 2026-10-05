// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import SwiftUI

@MainActor
struct ViewerTopToolbar: View {
  let pageSummary: String
  let overlaySummary: String
  @Binding var pageInput: String
  let canGoToPreviousPage: Bool
  let canGoToNextPage: Bool
  let canJumpToPage: Bool
  @Binding var isInMarkupMode: Bool
  @Binding var overlayMode: OverlayMode
  let showMarkupWarning: Bool
  let onFirst: () -> Void
  let onPrevious: () -> Void
  let onNext: () -> Void
  let onLast: () -> Void
  let onJumpToPage: () -> Void
  let onResetOverlayTelemetry: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      ViewThatFits(in: .horizontal) {
        navigationRowRegular
        navigationRowCompact
      }
      .buttonStyle(.bordered)

      ViewThatFits(in: .horizontal) {
        settingsRowRegular
        settingsRowCompact
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

  private var navigationRowRegular: some View {
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

      pageJumpField
    }
  }

  private var navigationRowCompact: some View {
    HStack(spacing: 8) {
      Button(action: onFirst) {
        Label("First", systemImage: "backward.end.fill")
      }
      .labelStyle(.iconOnly)
      .disabled(!canGoToPreviousPage)

      Button(action: onPrevious) {
        Label("Prev", systemImage: "chevron.left")
      }
      .labelStyle(.iconOnly)
      .disabled(!canGoToPreviousPage)

      Button(action: onNext) {
        Label("Next", systemImage: "chevron.right")
      }
      .labelStyle(.iconOnly)
      .disabled(!canGoToNextPage)

      Button(action: onLast) {
        Label("Last", systemImage: "forward.end.fill")
      }
      .labelStyle(.iconOnly)
      .disabled(!canGoToNextPage)

      Spacer()

      pageJumpField
    }
  }

  private var settingsRowRegular: some View {
    HStack(spacing: 12) {
      Text(pageSummary)
        .font(.footnote.monospacedDigit())

      Spacer()

      Toggle("Markup", isOn: $isInMarkupMode)
        .toggleStyle(.switch)
        .fixedSize()

      overlayModePicker

      Button("Reset Overlay", action: onResetOverlayTelemetry)
    }
  }

  private var settingsRowCompact: some View {
    VStack(spacing: 8) {
      HStack(spacing: 12) {
        Text(pageSummary)
          .font(.footnote.monospacedDigit())
        Spacer()
        Toggle("Markup", isOn: $isInMarkupMode)
          .toggleStyle(.switch)
          .fixedSize()
      }

      overlayModePicker

      HStack {
        Button("Reset Overlay", action: onResetOverlayTelemetry)
        Spacer()
      }
    }
  }

  private var overlayModePicker: some View {
    Picker("Overlay", selection: $overlayMode) {
      ForEach(OverlayMode.allCases) { mode in
        Text(mode.rawValue).tag(mode)
      }
    }
    .pickerStyle(.segmented)
    .frame(maxWidth: .infinity)
  }

  private var pageJumpField: some View {
    HStack(spacing: 8) {
      TextField("Page", text: $pageInput)
        .textFieldStyle(.roundedBorder)
        .frame(width: 64)
        .onSubmit {
          onJumpToPage()
        }

      Button("Go", action: onJumpToPage)
        .disabled(!canJumpToPage)
    }
  }
}

@MainActor
struct ViewerBottomToolbar: View {
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
