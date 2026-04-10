import PDFKit
import SwiftUI

public typealias PDFPageOverlayRelease = @MainActor (_ page: PDFPage) -> Void
public typealias PDFPageOverlayContentProvider = @MainActor (_ page: PDFPage) -> AnyView?
