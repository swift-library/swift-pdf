// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import Foundation
import SwiftUI

extension EnvironmentValues {
  @Entry
  var searchQueryBinding: Binding<String>? = nil

  @Entry
  var searchResultIndexBinding: Binding<Int?>? = nil

  @Entry
  var searchResultCountBinding: Binding<Int>? = nil

  @Entry
  var searchOptionsBinding: Binding<NSString.CompareOptions>? = nil

  @Entry
  var searchResultsBinding: Binding<[PDFSearchResult]>? = nil
}
