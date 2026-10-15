import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Defeitos achados na revisão independente de add-survey-import-export, cada um reproduzido antes da correção.
@Suite("survey-data-exchange: achados da revisão (unitários)")
struct SurveyReviewUnitTests {
    private typealias F = SurveyExchangeFixtures

    // MARK: Datas

    /// `DateTime.Parse` do .NET lê ano de dois dígitos com a janela de 2029: 00 a 29 viram 20xx, 30 a 99 viram 19xx.
    @Test func twoDigitYearsUseTheDotNetWindow() throws {
        #expect(ymd(try FieldParser.date("01/04/21", nullable: false)) == "2021-04-01")
        #expect(ymd(try FieldParser.date("15/03/16", nullable: false)) == "2016-03-15")
        #expect(ymd(try FieldParser.date("10/01/45", nullable: false)) == "1945-01-10")
        #expect(ymd(try FieldParser.date("01-04-29", nullable: false)) == "2029-04-01")
        #expect(ymd(try FieldParser.date("01/04/30 00:00:00", nullable: false)) == "1930-04-01")
        #expect(ymd(try FieldParser.date("01/04/2021", nullable: false)) == "2021-04-01")
    }

    // MARK: REC

    @Test func malformedRecWidthsAreInvalidInsteadOfCrashing() {
        for text in ["2\nA 0 0 0 0 0 0 4\nB 0 0 0 0 0 0 -2\nabcd\n", "1\nA 0 0 0 0 0 0 -3\nab\n",
                     "2\nA 0 0 0 0 0 0 9223372036854775807\nB 0 0 0 0 0 0 9223372036854775807\nab\n"] {
            expectInvalidStructure { () throws(ImportFailure) in _ = try RECParser.parse(text) }
        }
    }

    /// `DataTable.Columns.Add` recusa nome repetido (sem diferenciar maiúsculas).
    @Test func recWithRepeatedNamesIsInvalid() {
        expectInvalidStructure { () throws(ImportFailure) in
            _ = try RECParser.parse("2\nPESO 0 0 0 0 0 0 2\npeso 0 0 0 0 0 0 2\n1020\n")
        }
    }

    // MARK: DBF

    @Test func dbfWithRepeatedNamesIsInvalidAndEmptyNameBecomesColumnN() throws {
        let repeated = DBFBuilder.data(fields: [.init(name: "PESO", width: 2), .init(name: "Peso", width: 2)],
                                       records: [(false, ["10", "20"])])
        expectInvalidStructure { () throws(ImportFailure) in _ = try DBFParser.parse(repeated) }
        let unnamed = DBFBuilder.data(fields: [.init(name: "SEX", width: 1), .init(name: "", width: 2)], records: [(false, ["1", "ab"])])
        let table = try DBFParser.parse(unnamed)
        #expect(table.columns == ["SEX", "Column1"])
        #expect(table.rows == [["1", "ab"]])
    }

    @Test func dbfHeaderShorterThanOneDescriptorIsInvalid() {
        var bytes = [UInt8](DBFBuilder.data(fields: [.init(name: "SEX", width: 1)], records: [(false, ["1"])]))
        bytes[8] = 0
        bytes[9] = 0
        expectInvalidStructure { () throws(ImportFailure) in _ = try DBFParser.parse(Data(bytes)) }
    }

    /// Visual FoxPro guarda 263 bytes depois do terminador 0x0D; os descritores acabam no terminador.
    @Test func dbfDescriptorsStopAtTheTerminator() throws {
        var bytes = [UInt8](DBFBuilder.data(fields: [.init(name: "SEX", width: 1), .init(name: "PESO", width: 4)],
                                            records: [(false, ["1", "18.4"])]))
        let terminator = 32 + 32 * 2
        #expect(bytes[terminator] == 0x0D)
        bytes.insert(contentsOf: [UInt8](repeating: 0, count: 263), at: terminator + 1)
        let headerSize = Int(bytes[8]) | Int(bytes[9]) << 8 + 263
        bytes[8] = UInt8(headerSize & 0xFF)
        bytes[9] = UInt8(headerSize >> 8)
        let table = try DBFParser.parse(Data(bytes))
        #expect(table.columns == ["SEX", "PESO"])
        #expect(table.rows == [["1", "18.4"]])
    }

    // MARK: Texto delimitado

    /// Aspas abertas até o fim engoliriam todos os registros seguintes sem aviso.
    @Test func unclosedQuoteAtTheEndIsInvalid() {
        expectInvalidStructure { () throws(ImportFailure) in _ = try DelimitedParser.parse("A;B\n\"x;1\n2;3\n4;5\n", separator: ";") }
    }

    /// Linhas só de separadores (a área usada do Excel) não viram registros com sexo inválido.
    @Test func rowsWithOnlyEmptyFieldsAreSkipped() throws {
        let table = try DelimitedParser.parse("A;B\n1;2\n;;\n ; \n3;4\n", separator: ";")
        #expect(table.columns == ["A", "B"])
        #expect(table.rows == [["1", "2"], ["3", "4"]])
    }

    /// O separador padrão da extensão, presente na primeira linha, vence a contagem: o original sempre o usava.
    @Test func defaultSeparatorPresentInTheHeaderWins() throws {
        let txt = try ExternalTableReader.read(Data("Peso, kg, roupa\tSexo\n18\t1\n".utf8), kind: .delimited(fallbackSeparator: "\t"))
        #expect(txt.columns == ["Peso, kg, roupa", "Sexo"])
        let csv = try ExternalTableReader.read(Data("Nome, sobrenome, apelido;Sexo\nAna;2\n".utf8), kind: .delimited(fallbackSeparator: ";"))
        #expect(csv.columns == ["Nome, sobrenome, apelido", "Sexo"])
    }

    @Test func separatorIsDetectedOnTheFirstNonBlankLine() throws {
        let table = try ExternalTableReader.read(Data("   \nSex,Weight\n1,18\n".utf8), kind: .delimited(fallbackSeparator: ";"))
        #expect(table.columns == ["Sex", "Weight"])
        #expect(table.rows == [["1", "18"]])
    }

    // MARK: Montagem

    /// A idade digitada sai antes da derivação da medida: com as duas datas, vale a idade das datas.
    @Test func recumbentIsDerivedFromTheDatesWhenTheTypedAgeIsDropped() throws {
        let result = try ExternalSurveyBuilder.build(
            table: F.table(["Sex", "Date", "DOB", "Age"], [["1", "01/04/2021", "15/03/2016", "20"]]),
            mapping: [.sex: "Sex", .date: "Date", .dateOfBirth: "DOB", .ageInMonths: "Age"], name: "a")
        #expect(result.draft.records.first?.ageInMonths == nil)
        #expect(result.draft.records.first?.measuredRecumbent == false)
    }

    // MARK: XML

    @Test func blankSurveyNameIsInvalid() {
        expectInvalidStructure { () throws(ImportFailure) in _ = try SurveyXML.read(F.xml(F.survey(name: "  ", records: []))) }
    }

    /// Registro sem dados adicionais volta com `<Data />`: o atributo sempre escrito é o que o leitor do Windows exige
    /// (atributo ausente o derruba), e os valores são os mesmos.
    @Test func recordWithoutAdditionalDataComesBackWithEmptyData() throws {
        var record = F.record()
        record.additionalDataXML = nil
        let survey = ExchangeSurvey(survey: Survey(name: "a"), records: [record])
        var expected = record
        expected.additionalDataXML = "<Data />"
        #expect(try SurveyXML.read(SurveyXML.data([survey], resultsEngine: nil)).first?.records == [expected])
    }

    /// Textos acima dos limites do original são cortados na leitura e informados.
    @Test func readReportListsTheCutTexts() throws {
        let long = String(repeating: "a", count: 60)
        let report = try SurveyXML.readReport(F.xml(F.survey(name: long, records: [F.recordXML(["Notes": String(repeating: "n", count: 300)])])))
        #expect(report.surveys.first?.survey.name.count == 50)
        #expect(report.truncated.map(\.field) == ["Survey.Name", "Record.Notes"])
    }
}
