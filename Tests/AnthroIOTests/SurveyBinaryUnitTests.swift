import AnthroIO
import Foundation
import Testing

@Suite("survey-data-exchange: REC e DBF (unitários)")
struct SurveyBinaryUnitTests {
    @Test func recIgnoresZeroWidthFieldsAndTinyLines() throws {
        let text = "2 x\nSEX 6 1 6 1 0 0 1\nSKIP 6 1 6 1 0 0 0\n1\n\n2\n"
        let table = try RECParser.parse(text)
        #expect(table.columns == ["SEX"])
        #expect(table.rows == [])
        let wide = try RECParser.parse("2\nA 0 0 0 0 0 0 2\nB 0 0 0 0 0 0 1\nx\u{0}1\n")
        #expect(wide.rows == [["x", "1"]])
    }

    @Test func recRecordShorterThanTheFieldsIsInvalid() {
        expectInvalidStructure { () throws(ImportFailure) in _ = try RECParser.parse("1\nNAME 0 0 0 0 0 0 10\nabc\n") }
        expectInvalidStructure { () throws(ImportFailure) in _ = try RECParser.parse("x\n") }
    }

    @Test func dbfDecodesWindows1252ValuesAndToleratesExtraHeaderBytes() throws {
        var bytes = [UInt8](DBFBuilder.data(fields: [DBFBuilder.Field(name: "NOME", width: 4)], records: [(false, ["xxxx"])]))
        // Valor "João" em Windows-1252 no lugar de "xxxx".
        let valueOffset = bytes.count - 1 - 4
        bytes.replaceSubrange(valueOffset..<(valueOffset + 4), with: [0x4A, 0x6F, 0xE3, 0x6F])
        #expect(try DBFParser.parse(Data(bytes)).rows == [["João"]])
        // Cabeçalho declarado com 2 bytes a mais: os registros começam no tamanho declarado.
        var padded = [UInt8](DBFBuilder.data(fields: [DBFBuilder.Field(name: "SEX", width: 1)], records: [(false, ["2"])]))
        let headerSize = Int(padded[8]) | Int(padded[9]) << 8
        padded.insert(contentsOf: [0x00, 0x00], at: headerSize)
        padded[8] = UInt8((headerSize + 2) & 0xFF)
        #expect(try DBFParser.parse(Data(padded)).rows == [["2"]])
    }

    @Test func dbfShorterThanItsHeaderIsInvalid() {
        expectInvalidStructure { () throws(ImportFailure) in _ = try DBFParser.parse(Data([0x03, 0x00])) }
    }
}
