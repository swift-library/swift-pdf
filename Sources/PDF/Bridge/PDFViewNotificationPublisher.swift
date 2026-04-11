import Combine
import Foundation
import PDFKit

@MainActor
final class PDFViewNotificationPublisher {
  private let center: NotificationCenter

  init(center: NotificationCenter = .default) {
    self.center = center
  }

  func onPageChanged<Observer: AnyObject>(
    for pdfView: PDFView,
    observer: Observer,
    storeIn cancellables: inout Set<AnyCancellable>,
    perform action: @escaping @MainActor (Observer) -> () -> Void
  ) {
    observe(
      pageChanged(for: pdfView),
      observer: observer,
      storeIn: &cancellables,
      perform: action
    )
  }

  func onScaleChanged<Observer: AnyObject>(
    for pdfView: PDFView,
    observer: Observer,
    storeIn cancellables: inout Set<AnyCancellable>,
    perform action: @escaping @MainActor (Observer) -> () -> Void
  ) {
    observe(
      scaleChanged(for: pdfView),
      observer: observer,
      storeIn: &cancellables,
      perform: action
    )
  }

  private func pageChanged(for pdfView: PDFView) -> AnyPublisher<Notification, Never> {
    notificationPublisher(
      for: Notification.Name.PDFViewPageChanged,
      object: pdfView
    )
  }

  private func scaleChanged(for pdfView: PDFView) -> AnyPublisher<Notification, Never> {
    notificationPublisher(
      for: Notification.Name.PDFViewScaleChanged,
      object: pdfView
    )
  }

  private func observe<Observer: AnyObject>(
    _ publisher: AnyPublisher<Notification, Never>,
    observer: Observer,
    storeIn cancellables: inout Set<AnyCancellable>,
    perform action: @escaping @MainActor (Observer) -> () -> Void
  ) {
    publisher.sink { [weak observer] _ in
      guard let observer else {
        return
      }

      if Thread.isMainThread {
        MainActor.assumeIsolated {
          action(observer)()
        }
        return
      }

      Task { @MainActor [weak observer] in
        guard let observer else {
          return
        }
        action(observer)()
      }
    }
    .store(in: &cancellables)
  }

  private func notificationPublisher(
    for name: Notification.Name,
    object: AnyObject?
  ) -> AnyPublisher<Notification, Never> {
    center.publisher(for: name, object: object)
      .eraseToAnyPublisher()
  }
}
