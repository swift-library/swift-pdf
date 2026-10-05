// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import SwiftUI

extension Binding where Value: Equatable {
  func setIfChanged(_ value: Value) {
    guard wrappedValue != value else {
      return
    }

    wrappedValue = value
  }
}
