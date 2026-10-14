import AnthroIO
import Foundation
import Testing

/// Cenário de aspas no escritor delimitado (change add-individual-import-export).
@Suite("individual-data-exchange: escritor delimitado")
struct DelimitedWriterTests {
    // Scenario: Valor com aspas e separador ausente
    @Test func valorComAspasEDuplicadoEPontoEVirgulaNoTxtSemAspas() {
        let text = DelimitedWriter.write(header: ["Notes", "Place"], rows: [["disse \"não\"", "pesada; sem sapatos"]],
                                         separator: "\t")
        #expect(text == "Notes\tPlace\r\n\"disse \"\"não\"\"\"\tpesada; sem sapatos\r\n")
    }
}
