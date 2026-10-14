import AnthroCore
import AppKit
import Foundation

/// Copiar, exportar e imprimir o gráfico (substitui `CopyToClipboard` e `Print` do NPlot).
public enum ChartExport {
    public static func pngData(_ image: CGImage) -> Data? {
        nil
    }

    public static func pdfData(_ image: CGImage) -> Data? {
        nil
    }

    public static func copy(_ image: CGImage?, to pasteboard: NSPasteboard) -> Bool {
        false
    }

    @MainActor
    public static func printOperation(pdfData: Data) -> NSPrintOperation? {
        nil
    }

    public static func suggestedFileName(indicator: Indicator, mode: ChartDisplayMode, date: Date) -> String {
        ""
    }
}
