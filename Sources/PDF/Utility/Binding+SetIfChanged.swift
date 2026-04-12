import SwiftUI

extension Binding where Value: Equatable {
  func setIfChanged(_ value: Value) {
    guard wrappedValue != value else {
      return
    }

    wrappedValue = value
  }
}
