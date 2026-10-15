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

    public func applicationURL(bundleIdentifier: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }

    public func open(_ file: URL, withApplicationAt application: URL?) {
        guard let application else {
            NSWorkspace.shared.open(file)
            return
        }
        NSWorkspace.shared.open([file], withApplicationAt: application, configuration: NSWorkspace.OpenConfiguration())
    }
}

/// Excel, depois Numbers, depois o aplicativo padrão para o arquivo (o COM do original com recuo para `Process.Start`).
public enum ReportLauncher {
    public static let excelBundleID = "com.microsoft.Excel"
    public static let numbersBundleID = "com.apple.iWork.Numbers"

    /// O identificador do aplicativo usado, ou `nil` com o aplicativo padrão.
    @discardableResult
    public static func open(_ file: URL, using opener: ReportOpening) -> String? {
        for bundleID in [excelBundleID, numbersBundleID] {
            if let application = opener.applicationURL(bundleIdentifier: bundleID) {
                opener.open(file, withApplicationAt: application)
                return bundleID
            }
        }
        opener.open(file, withApplicationAt: nil)
        return nil
    }
}
