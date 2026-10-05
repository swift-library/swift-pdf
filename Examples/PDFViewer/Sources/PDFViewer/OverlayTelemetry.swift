import Observation

@MainActor
@Observable
final class OverlayTelemetry {
  private(set) var providedCount = 0
  private(set) var releasedCount = 0
  private(set) var tapCount = 0
  private(set) var activePages: Set<String> = []
  private(set) var lastTappedPage: String?

  func noteProvided(_ pageKey: String) {
    guard !activePages.contains(pageKey) else {
      return
    }
    providedCount += 1
    activePages.insert(pageKey)
  }

  func noteReleased(_ pageKey: String) {
    guard activePages.contains(pageKey) else {
      return
    }
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
