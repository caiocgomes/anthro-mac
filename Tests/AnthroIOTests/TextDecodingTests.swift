import AnthroIO
import Foundation
import Testing

/// Cenários da decodificação de texto importado (change add-survey-import-export).
@Suite("survey-data-exchange: decodificação de texto")
struct TextDecodingTests {
    // Scenario: Arquivo do Excel em Windows-1252
    @Test func arquivoDoExcelEmWindows1252ViraJoao() {
        #expect(TextDecoding.decode(Data([0x4A, 0x6F, 0xE3, 0x6F])) == "João")
    }

    // Scenario: Arquivo UTF-8 com BOM
    @Test func arquivoUtf8ComBomRemoveOBom() {
        #expect(TextDecoding.decode(Data([0xEF, 0xBB, 0xBF]) + Data("João".utf8)) == "João")
    }

    // Scenario: Arquivo UTF-16 LE com BOM
    @Test func arquivoUtf16LeComBomEhDecodificado() {
        #expect(TextDecoding.decode(Data([0xFF, 0xFE, 0x53, 0x00, 0x65, 0x00, 0x78, 0x00])) == "Sex")
    }
}
