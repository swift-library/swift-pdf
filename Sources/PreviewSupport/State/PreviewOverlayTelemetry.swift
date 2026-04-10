#if DEBUG && canImport(SwiftUI)
  import Observation

  @MainActor
  @Observable
  final class PreviewOverlayTelemetry {
    private(set) var providedCount = 0
    private(set) var releasedCount = 0
    private(set) var tapCount = 0
    private(set) var activePages: Set<String> = []
    private(set) var lastTappedPage: String?

    func noteProvided(_ pageKey: String) {
      providedCount += 1
      activePages.insert(pageKey)
    }

    func noteReleased(_ pageKey: String) {
      releasedCount += 1
      activePages.remove(pageKey)
    }

    func noteTapped(_ pageKey: String) {
      tapCount += 1
      lastTappedPage = pageKey
    }

    func reset() {
      providedCount = 0
      releasedCount = 0
      tapCount = 0
      activePages.removeAll(keepingCapacity: false)
      lastTappedPage = nil
    }
  }
#endif
