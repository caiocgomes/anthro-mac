import AppKit
import Foundation

/// Abertura do relatório gravado (`Utils.OpenExcel`, design D10); o protocolo permite testar a ordem sem abrir apps.
public protocol ReportOpening {
    func applicationURL(bundleIdentifier: String) -> URL?
    func open(_ file: URL, withApplicationAt application: URL?)
}

/// `NSWorkspace` de verdade.
public struct WorkspaceReportOpener: ReportOpening {
    public init() {}

    public func applicationURL(bundleIdentifier: String) -> URL? { nil }

    public func open(_ file: URL, withApplicationAt application: URL?) {}
}

/// Excel, depois Numbers, depois o aplicativo padrão.
public enum ReportLauncher {
    public static let excelBundleID = "com.microsoft.Excel"
    public static let numbersBundleID = "com.apple.iWork.Numbers"

    @discardableResult
    public static func open(_ file: URL, using opener: ReportOpening) -> String? { nil }
}
