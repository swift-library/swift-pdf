import PDFKit
#if canImport(AppKit)
  import AppKit
#elseif canImport(UIKit)
  import UIKit
#endif

private extension Int {
  func clamped(to pageCount: Int) -> Int {
    guard pageCount > 0 else {
      return 0
    }

    return Swift.min(Swift.max(self, 0), pageCount - 1)
  }
}

extension PDFView {
  func goToPage(at pageIndex: Int) {
    guard let document = document else {
      return
    }

    let pageCount = document.pageCount
    guard pageCount > 0 else {
      return
    }

    let destinationIndex = pageIndex.clamped(to: pageCount)
    guard destinationIndex != currentPageIndex,
      let page = document.page(at: destinationIndex)
    else {
      return
    }

    go(to: page)
  }

  func goToFirstPage() {
    #if canImport(AppKit)
      goToFirstPage(nil)
    #elseif canImport(UIKit)
      guard let firstPage = document?.page(at: 0) else {
        return
      }

      // On iOS, direct page-target navigation is more reliable here than
      // goToFirstPage(_:), which has been inconsistent in driving the settled
      // page-update path used by our SwiftUI bindings.
      go(to: firstPage)
    #endif
  }

  func goToLastPage() {
    #if canImport(AppKit)
      goToLastPage(nil)
    #elseif canImport(UIKit)
      guard let document = document else {
        return
      }

      let lastIndex = document.pageCount - 1
      guard lastIndex >= 0,
        let lastPage = document.page(at: lastIndex)
      else {
        return
      }

      // On iOS, direct page-target navigation is more reliable here than
      // goToLastPage(_:), which has been inconsistent in driving the settled
      // page-update path used by our SwiftUI bindings.
      go(to: lastPage)
    #endif
  }

  func goToSelection(_ selection: PDFSelection) {
    setCurrentSelection(selection, animate: true)
    go(to: selection)
  }

  var currentPageIndex: Int {
    guard let document = document,
      document.pageCount > 0,
      let currentPage = currentPage
    else {
      return 0
    }

    return document.index(for: currentPage).clamped(to: document.pageCount)
  }
}
