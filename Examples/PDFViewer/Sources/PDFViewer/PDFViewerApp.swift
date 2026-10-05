// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDF
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

#if canImport(AppKit)
  import AppKit
#endif

@main
struct PDFViewerApp: App {
  init() {
    #if canImport(AppKit)
      NSApplication.shared.setActivationPolicy(.regular)
      NSApplication.shared.activate()
    #endif
  }

  var body: some Scene {
    WindowGroup("PDF Viewer") {
      ContentView()
    }
  }
}

struct ContentView: View {
  @State private var source = PDFDocument.Representation.data(SampleDocument.data())
  @State private var isImporting = false
  @State private var importError: String?

  var body: some View {
    NavigationStack {
      ViewerScreen(source: source)
        .toolbar {
          Button("Open PDF", systemImage: "folder") {
            isImporting = true
          }
        }
    }
    .fileImporter(isPresented: $isImporting, allowedContentTypes: [.pdf]) { result in
      open(result)
    }
    .alert(
      "Could not open the file",
      isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(importError ?? "")
    }
  }

  private func open(_ result: Result<URL, any Error>) {
    do {
      let url = try result.get()
      let isScoped = url.startAccessingSecurityScopedResource()
      defer {
        if isScoped { url.stopAccessingSecurityScopedResource() }
      }
      source = .data(try Data(contentsOf: url))
    } catch {
      importError = error.localizedDescription
    }
  }
}

#Preview("Sample document") {
  ViewerScreen(source: .data(SampleDocument.data()))
}
