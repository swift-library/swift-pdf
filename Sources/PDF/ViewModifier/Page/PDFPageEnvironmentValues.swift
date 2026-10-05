// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import SwiftUI

extension EnvironmentValues {
  @Entry
  var currentPageBinding: Binding<Int>? = nil

  @Entry
  var pageCountBinding: Binding<Int>? = nil

  @Entry
  var scaleFactorBinding: Binding<CGFloat>? = nil
}
