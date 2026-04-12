import SwiftUI

extension EnvironmentValues {
  @Entry
  var currentPageBinding: Binding<Int>? = nil

  @Entry
  var pageCountBinding: Binding<Int>? = nil

  @Entry
  var scaleFactorBinding: Binding<CGFloat>? = nil
}
