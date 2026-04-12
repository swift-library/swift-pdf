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
  }
}
