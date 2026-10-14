import AnthroCore
import AppKit
import Foundation
import PDFKit
import UniformTypeIdentifiers

/// Copiar, exportar e imprimir o gráfico (substitui `CopyToClipboard` e `Print` do NPlot, design D10).
public enum ChartExport {
    public static func pngData(_ image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination) ? data as Data : nil
    }

    /// PDF de uma página do tamanho da imagem.
    public static func pdfData(_ image: CGImage) -> Data? {
        let data = NSMutableData()
        var box = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        guard let consumer = CGDataConsumer(data: data),
              let context = CGContext(consumer: consumer, mediaBox: &box, nil) else { return nil }
        context.beginPDFPage(nil)
        context.draw(image, in: box)
        context.endPDFPage()
        context.closePDF()
        return data as Data
    }

    /// Sem imagem, a área de transferência fica como estava.
    public static func copy(_ image: CGImage?, to pasteboard: NSPasteboard) -> Bool {
        guard let image, let png = pngData(image) else { return false }
        pasteboard.clearContents()
        return pasteboard.setData(png, forType: .png)
    }

    /// `nil` quando os dados não formam um PDF legível.
    @MainActor
    public static func printOperation(pdfData: Data) -> NSPrintOperation? {
        guard let document = PDFDocument(data: pdfData), document.pageCount > 0 else { return nil }
        let printInfo = NSPrintInfo.shared.copy() as? NSPrintInfo ?? NSPrintInfo()
        return document.printOperation(for: printInfo, scalingMode: .pageScaleToFit, autoRotate: true)
    }

    /// "{indicador} - {modo} - {AAAA-MM-DD}", com "/" trocada por "-".
    public static func suggestedFileName(indicator: Indicator, mode: ChartDisplayMode, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        let name = "\(L10n.Indicators.title(indicator, isLength: nil)) - \(mode.title) - \(formatter.string(from: date))"
        return name.replacingOccurrences(of: "/", with: "-")
    }
}
