// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDFKit
import Testing

@testable import PDF

extension PDFTests {
  @Suite("Configuration")
  @MainActor
  final class Configuration: PDFKitSuite {
    @Test
    func viewerConfigurationDefaultsMatchSupportedModifierDefaults() {
      let configuration = PDFViewConfiguration()

      #expect(configuration.displayMode == .singlePage)
      #expect(configuration.displayDirection == .horizontal)
      #expect(configuration.autoScales == false)
      #expect(configuration.isInMarkupMode == false)
    }

    @Test
    func configureUsingAppliesResolvedConfigurationToPDFView() {
      let pdfView = PDFView()
      let configuration = PDFViewConfiguration(
        displayMode: .twoUpContinuous,
        displayDirection: .vertical,
        autoScales: true,
        isInMarkupMode: true
      )

      pdfView.configure(using: configuration)

      #expect(pdfView.displayMode == .twoUpContinuous)
      #expect(pdfView.displayDirection == .vertical)
      #expect(pdfView.autoScales == true)
      #expect(pdfView.isInMarkupMode == true)
    }

    @Test
    func repeatedConfigurationDoesNotRewriteSettledPDFKitProperties() {
      let pdfView = ConfigurationTrackingPDFView()
      let configuration = PDFViewConfiguration(
        displayMode: .twoUpContinuous,
        displayDirection: .vertical,
        autoScales: true,
        isInMarkupMode: true
      )

      pdfView.configure(using: configuration)
      let firstWriteCounts = pdfView.writeCounts

      pdfView.configure(using: configuration)

      #expect(firstWriteCounts.displayMode > 0)
      #expect(firstWriteCounts.autoScales > 0)
      #expect(firstWriteCounts.isInMarkupMode > 0)
      #expect(pdfView.writeCounts == firstWriteCounts)
    }
  }
}

@MainActor
private final class ConfigurationTrackingPDFView: PDFView {
  struct WriteCounts: Equatable {
    var displayMode = 0
    var displayDirection = 0
    var autoScales = 0
    var isInMarkupMode = 0
  }

  private(set) var writeCounts = WriteCounts()

  override var displayMode: PDFDisplayMode {
    didSet { writeCounts.displayMode += 1 }
  }

  override var displayDirection: PDFDisplayDirection {
    didSet { writeCounts.displayDirection += 1 }
  }

  override var autoScales: Bool {
    didSet { writeCounts.autoScales += 1 }
  }

  override var isInMarkupMode: Bool {
    didSet { writeCounts.isInMarkupMode += 1 }
  }
}
