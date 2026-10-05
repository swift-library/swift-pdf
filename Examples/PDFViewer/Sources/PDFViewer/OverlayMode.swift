// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import Foundation

enum OverlayMode: String, CaseIterable, Identifiable {
  case off = "Off"
  case badge = "Badge"
  case interactive = "Interactive"

  var id: String { rawValue }
}
