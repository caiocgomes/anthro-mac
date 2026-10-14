import AnthroFeatures
import AppKit
import Foundation
import PDFKit
import Testing

/// Cenários de cópia, exportação e impressão do gráfico (capability growth-charts).
@MainActor
@Suite("growth-charts: ChartExport")
struct ChartExportTests {
    init() {
        _ = NSApplication.shared
    }

    /// Imagem RGB de 400 por 300 pixels.
    private func image() -> CGImage {
        let context = CGContext(data: nil, width: 400, height: 300, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(red: 0.1, green: 0.5, blue: 0.6, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 400, height: 300))
        return context.makeImage()!
    }

    private func pasteboard() -> NSPasteboard {
        NSPasteboard(name: NSPasteboard.Name("anthro-test-\(UUID().uuidString)"))
    }

    private let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47]

    // Scenario: Cópia em PNG
    @Test func copiaEmPngParaAreaDeTransferencia() throws {
        let board = pasteboard()
        defer { board.releaseGlobally() }
        #expect(ChartExport.copy(image(), to: board) == true)
        let data = try #require(board.data(forType: .png))
        #expect(Array(data.prefix(4)) == pngSignature)
    }

    // Scenario: Cópia sem imagem
    @Test func copiaSemImagemNaoAlteraAreaDeTransferencia() {
        let board = pasteboard()
        defer { board.releaseGlobally() }
        #expect(ChartExport.copy(image(), to: board) == true)
        let count = board.changeCount
        #expect(ChartExport.copy(nil, to: board) == false)
        #expect(board.changeCount == count)
    }

    // Scenario: Exportações válidas
    @Test func exportacoesValidasPngPdfEImpressao() throws {
        let png = try #require(ChartExport.pngData(image()))
        #expect(Array(png.prefix(4)) == pngSignature)
        let pdf = try #require(ChartExport.pdfData(image()))
        #expect(String(decoding: pdf.prefix(4), as: UTF8.self) == "%PDF")
        #expect(PDFDocument(data: pdf)?.pageCount == 1)
        #expect(ChartExport.printOperation(pdfData: pdf) != nil)
    }

    // Scenario: Nome de arquivo sem barra
    @Test func nomeDeArquivoSemBarra() {
        #expect(ChartExport.suggestedFileName(indicator: .lengthOrHeightForAge, mode: .percentile, date: day(2026, 10, 14))
                == "Comprimento-estatura para idade - Percentil - 2026-10-14")
    }

    // Scenario: PDF inválido para impressão
    @Test func pdfInvalidoParaImpressaoDevolveNil() throws {
        let pdf = try #require(ChartExport.pdfData(image()))
        #expect(ChartExport.printOperation(pdfData: pdf) != nil)
        #expect(ChartExport.printOperation(pdfData: Data("isto não é um PDF".utf8)) == nil)
    }
}
