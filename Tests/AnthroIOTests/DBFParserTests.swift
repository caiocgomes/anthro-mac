import AnthroIO
import Foundation
import Testing

/// Cenários da leitura de DBF (change add-survey-import-export).
@Suite("survey-data-exchange: DBF")
struct DBFParserTests {
    private let fields = [DBFBuilder.Field(name: "SEX", width: 1), DBFBuilder.Field(name: "WEIGHT", width: 6)]

    // Scenario: DBF com dois registros
    @Test func dbfComDoisRegistrosLeCamposEValores() throws {
        let data = DBFBuilder.data(fields: fields, records: [(false, ["1", "16.50"]), (false, ["2", "12.30"])])
        let table = try DBFParser.parse(data)
        #expect(table.columns == ["SEX", "WEIGHT"])
        #expect(table.rows == [["1", "16.50"], ["2", "12.30"]])
    }

    // Scenario: Registro apagado
    @Test func registroApagadoNoDbfEhIgnorado() throws {
        let data = DBFBuilder.data(fields: fields, records: [(false, ["1", "16.50"]), (true, ["2", "12.30"])])
        #expect(try DBFParser.parse(data).rows == [["1", "16.50"]])
    }

    // Scenario: DBF truncado
    @Test func dbfTruncadoFalha() {
        let data = DBFBuilder.data(fields: fields, records: [(false, ["1", "16.50"])], declaredRecords: 2).dropLast()
        expectInvalidStructure { () throws(ImportFailure) in _ = try DBFParser.parse(Data(data)) }
    }
}
