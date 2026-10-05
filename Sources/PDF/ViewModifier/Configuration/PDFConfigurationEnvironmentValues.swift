// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDFKit
import SwiftUI

extension EnvironmentValues {
  @Entry
  var displayMode: PDFDisplayMode? = nil

  @Entry
  var displayDirection: PDFDisplayDirection? = nil

  @Entry
  var autoScales: Bool? = nil

  @Entry
  var isInMarkupMode: Bool? = nil
}
