import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Cenários do XML de inquéritos: leitura, escrita e ida e volta (change add-survey-import-export).
@Suite("survey-data-exchange: XML de inquéritos")
struct SurveyXMLTests {
    private typealias F = SurveyExchangeFixtures

    private func document(_ data: Data) throws -> XMLDocument {
        try #require(try? XMLDocument(data: data))
    }

    private func readOne(_ record: String) throws(ImportFailure) -> SurveyRecord? {
        try SurveyXML.read(F.xml(F.survey(records: [record]))).first?.records.first
    }

    // Scenario: XML com dois inquéritos
    @Test func xmlComDoisInqueritosELido() throws {
        let surveys = try SurveyXML.read(try ExchangeFixtures.fixture("ns-two-surveys.xml"))
        #expect(surveys.map(\.survey.name) == ["Escola A", "Escola B"])
        #expect(surveys.map(\.records.count) == [2, 1])
        #expect(surveys.flatMap(\.records).map(\.weightingFactor) == [d("1"), d("2.5"), d("0.75")])
        #expect(surveys.first?.records.first?.weight == d("18.4"))
    }

    // Scenario: Fator de ponderação sem truncamento
    @Test func fatorDePonderacaoDoXmlNaoEhTruncado() throws {
        #expect(try readOne(F.recordXML(["WeightingFactor": "1.2345"]))?.weightingFactor == d("1.2345"))
    }

    // Scenario: Registro sem CreatedBy
    @Test func registroSemCreatedByRejeitaOArquivo() {
        expectInvalidStructure { () throws(ImportFailure) in _ = try readOne(F.recordXML(["CreatedBy": nil])) }
    }

    // Scenario: Opções malformadas
    @Test func opcoesMalformadasRejeitamOArquivo() {
        let data = F.xml(F.survey(options: "&lt;Opt&gt;&lt;O ID=&quot;x&quot;&gt;", records: [F.recordXML()]))
        expectInvalidStructure { () throws(ImportFailure) in _ = try SurveyXML.read(data) }
    }

    // Scenario: Arquivo do WHO Anthro
    @Test func arquivoDoWhoAnthroConverteDiasEmMeses() throws {
        let record = try readOne(F.recordXML(["HC": "48.5", "Age": "1843", "Date": ""]))
        #expect(record?.ageInMonths == d("1843") / d("30.4375"))
    }

    // Scenario: Arquivo do AnthroPlus
    @Test func arquivoDoAnthroPlusLeIdadeEmMeses() throws {
        #expect(try readOne(F.recordXML(["Age": "60.55"]))?.ageInMonths == d("60.55"))
    }

    // Scenario: XML com as duas datas e a idade
    @Test func idadeComAsDuasDatasEhDescartadaNoXml() throws {
        let record = try #require(try readOne(F.recordXML(["DateOfBirth": "15-03-2016 00:00:00", "Age": "70"])))
        #expect(ymd(record.visitDate) == "2021-04-01")
        #expect(ymd(record.dateOfBirth) == "2016-03-15")
        #expect(record.ageInMonths == nil)
    }

    // Scenario: Inquérito com registros e resultados
    @Test func inqueritoComRegistrosEResultadosTemTodosOsAtributos() throws {
        let survey = ExchangeSurvey(survey: Survey(name: "Escola A"), records: [F.record()])
        let doc = try document(SurveyXML.data([survey], resultsEngine: try AnthroEngine.shared()))
        let record = try #require(try doc.nodes(forXPath: "/Surveys/Survey/Records/Record").first as? XMLElement)
        #expect((record.attributes ?? []).compactMap(\.name) == [
            "Date", "Cluster", "Team", "DisplayID", "Household", "WeightingFactor", "FirstName", "LastName", "DateOfBirth",
            "DateOfBirthIsApprox", "Age", "Sex", "Weight", "Height", "IsRecumbent", "HasOedema", "Notes", "AdditionalData",
            "CreatedBy", "WAZ", "HAZ", "BAZ", "BMI"])
    }

    // Scenario: Inquérito sem registros
    @Test func inqueritoSemRegistrosNaoTemFilhos() throws {
        let doc = try document(SurveyXML.data([ExchangeSurvey(survey: Survey(name: "Vazio"), records: [])], resultsEngine: nil))
        let surveys = try doc.nodes(forXPath: "/Surveys/Survey")
        #expect(surveys.count == 1)
        #expect(surveys.first?.childCount == 0)
    }

    // Scenario: CreatedBy na exportação de inquérito
    @Test func createdByNaExportacaoDeInqueritoEhFixo() throws {
        let survey = ExchangeSurvey(survey: Survey(name: "Escola A"), records: [F.record()])
        let doc = try document(SurveyXML.data([survey], resultsEngine: nil))
        #expect(try doc.nodes(forXPath: "//@CreatedBy").map(\.stringValue) == ["AnthroPlus", "AnthroPlus"])
        let lines = F.lines(SurveyDelimitedExport.data(survey, resultsEngine: nil, format: .semicolonCSV))
        let header = lines.first?.components(separatedBy: ";") ?? []
        let row = lines.dropFirst().first?.components(separatedBy: ";") ?? []
        #expect(header.firstIndex(of: "CreatedBy").flatMap { row.indices.contains($0) ? row[$0] : nil } == "AnthroPlus")
    }

    // Scenario: CreatedBy lido e descartado
    @Test func createdByLidoNoXmlDeInqueritoEhDescartado() throws {
        let surveys = try SurveyXML.read(F.xml(F.survey(records: [F.recordXML()])))
        #expect(surveys.count == 1)
        let doc = try document(SurveyXML.data(surveys, resultsEngine: nil))
        let values = try doc.nodes(forXPath: "//@CreatedBy").map(\.stringValue)
        #expect(values == ["AnthroPlus", "AnthroPlus"])
    }

    // Scenario: Exportar e reler inquérito
    @Test func exportarERelerInqueritoPreservaCampos() throws {
        var typed = F.record(sex: .boy, visit: nil, birth: nil, months: "61.25", weight: "19.5", height: "112.3", displayID: 2,
                             weightingFactor: "1.75")
        typed.cluster = 3
        typed.team = 1
        typed.household = 7
        typed.firstName = "Bia"
        typed.notes = "com \"aspas\" & <sinais>"
        var approx = F.record(birth: "2015-01-10", displayID: 3)
        approx.dateOfBirthIsApprox = true
        approx.measuredRecumbent = false
        approx.hasOedema = true
        let survey = ExchangeSurvey(survey: Survey(name: "Escola A", notes: "manhã"), records: [F.record(), typed, approx])
        let data = SurveyXML.data([survey], resultsEngine: nil)
        let doc = try document(data)
        let ages = try doc.nodes(forXPath: "/Surveys/Survey/Records/Record/@Age").map(\.stringValue)
        #expect(ages.first == "60.5503080082")
        let reread = try SurveyXML.read(data)
        #expect(reread.first?.records == survey.records)
        #expect(reread.first?.survey.name == "Escola A")
        #expect(reread.first?.survey.notes == "manhã")
    }

    // Scenario: Inquérito com dados adicionais na ida e volta
    @Test func inqueritoComDadosAdicionaisNaIdaEVolta() throws {
        let definition = #"<Data><Cat ID="Escola" Descr=""><Txt ID="Série" Descr=""></Txt></Cat></Data>"#
        var record = F.record()
        record.additionalDataXML = #"<Data><Cat ID="Escola" Descr=""><Txt ID="Série" Descr="">3º ano &amp; "B"</Txt></Cat></Data>"#
        let survey = ExchangeSurvey(survey: Survey(name: "Escola A", additionalDataDefinitionXML: definition), records: [record])
        let reread = try SurveyXML.read(SurveyXML.data([survey], resultsEngine: nil))
        #expect(reread.first?.survey.additionalDataDefinitionXML == definition)
        #expect(reread.first?.records.first?.additionalDataXML == record.additionalDataXML)
    }
}
