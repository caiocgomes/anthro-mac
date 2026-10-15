import AnthroCore
import AnthroFeatures
import AnthroIO
import AnthroStore
import Foundation
import Testing

/// Cenários do modelo de importação e exportação do inquérito (change add-survey-import-export).
@MainActor
@Suite("survey-data-exchange: modelo da tela")
struct SurveyExchangeModelTests {
    let db: AnthroDatabase
    let presenter = RecordingDraftPresenter()
    let model: SurveyExchangeModel
    let directory: URL

    init() throws {
        db = try SurveyFixtures.makeDatabase()
        let exchange = RepositorySurveyExchange(database: db, surveys: SurveyRepository(database: db))
        model = SurveyExchangeModel(source: exchange, sink: exchange, presenter: presenter, engine: try AnthroEngine.shared())
        directory = try SurveyExchangeTestFiles.directory()
    }

    private func file(_ name: String, _ text: String) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try Data(text.utf8).write(to: url)
        return url
    }

    private func csv(_ rows: [String]) throws -> URL {
        try file("escola_a.csv", (["ID;Sex;Weight"] + rows).joined(separator: "\r\n") + "\r\n")
    }

    // Scenario: Importar CSV até o rascunho
    @Test func importarCsvAteORascunhoNaoGrava() throws {
        model.beginImport(from: try csv(["1;1;18", "2;2;19", "3;1;20", "4;2;21", "5;1;22"]))
        guard case .mapping(let columns, let mapping) = model.phase else {
            Issue.record("expected the mapping phase, got \(model.phase)")
            return
        }
        #expect(columns == ["ID", "Sex", "Weight"])
        #expect(mapping[.sex] == "Sex")
        model.confirmMapping()
        #expect(presenter.drafts.count == 1)
        #expect(presenter.drafts.first?.survey.name == "escola_a")
        #expect(presenter.drafts.first?.records.count == 5)
        #expect(try SurveyExchangeTestFiles.count(db, "surveys") == 0)
    }

    // Scenario: Cancelar o mapeamento
    @Test func cancelarOMapeamentoVoltaAoInicioSemRascunho() throws {
        model.beginImport(from: try csv(["1;1;18"]))
        guard case .mapping = model.phase else {
            Issue.record("expected the mapping phase, got \(model.phase)")
            return
        }
        model.cancelImport()
        #expect(model.phase == .idle)
        #expect(presenter.drafts.isEmpty)
    }

    // Scenario: Aviso de registros descartados
    @Test func avisoDeRegistrosDescartadosListaLinhaECampo() throws {
        model.beginImport(from: try csv(["1;1;18", "2;2;19", "3;x;20"]))
        model.confirmMapping()
        guard case .finished(let warning?) = model.phase else {
            Issue.record("expected a finished phase with a warning, got \(model.phase)")
            return
        }
        #expect(warning.hasPrefix("O arquivo 'escola_a.csv' foi importado, mas uma ou mais linhas foram ignoradas por campos obrigatórios ausentes ou inválidos."))
        #expect(warning.contains("linha 3, campo 'Sex'."))
    }

    // Scenario: Aviso só de campos inválidos
    @Test func avisoSoDeCamposInvalidos() throws {
        model.beginImport(from: try csv(["1;1;18", "2;2;300"]))
        model.confirmMapping()
        #expect(model.phase == .finished(warning: "O arquivo 'escola_a.csv' foi importado, mas um ou mais campos estavam ausentes ou continham valores inválidos."))
    }

    // Scenario: Importação limpa
    @Test func importacaoLimpaTerminaSemAviso() throws {
        model.beginImport(from: try csv(["1;1;18", "2;2;19"]))
        model.confirmMapping()
        #expect(model.phase == .finished(warning: nil))
        #expect(presenter.drafts.count == 1)
    }

    // Scenario: Dois inquéritos gravados
    @Test func doisInqueritosGravadosNumaTransacao() throws {
        model.beginImport(from: try file("inqueritos.xml", SurveyExchangeTestFiles.twoSurveysXML()))
        #expect(model.phase == .finished(warning: nil))
        #expect(try SurveyExchangeTestFiles.count(db, "surveys") == 2)
        #expect(try SurveyExchangeTestFiles.count(db, "records") == 3)
        #expect(presenter.drafts.isEmpty)
    }

    // Scenario: Sexo inválido no XML
    @Test func sexoInvalidoNoXmlNaoGravaNada() throws {
        model.beginImport(from: try file("inqueritos.xml", SurveyExchangeTestFiles.twoSurveysXML(secondSex: "x")))
        guard case .failed(let message) = model.phase else {
            Issue.record("expected the failed phase, got \(model.phase)")
            return
        }
        #expect(message.hasPrefix("Não foi possível importar o arquivo 'inqueritos.xml': o formato do arquivo é inválido."))
        #expect(try SurveyExchangeTestFiles.count(db, "surveys") == 0)
    }

    // Scenario: Dois inquéritos em CSV
    @Test func doisInqueritosEmCsvExportaSoOPrimeiro() throws {
        let first = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        try SurveyFixtures.insertRecord(db, surveyID: first, position: 0, firstName: "Ana")
        let second = try SurveyFixtures.insertSurvey(db, name: "Escola B")
        try SurveyFixtures.insertRecord(db, surveyID: second, position: 0, firstName: "Bia")
        try SurveyFixtures.insertRecord(db, surveyID: second, position: 1, firstName: "Caio")
        model.selectedSurveyIDs = [first, second]
        let url = directory.appendingPathComponent("inqueritos.csv")
        #expect(try model.export(format: .semicolonCSV, to: url) == .onlyFirstSurveyExported)
        let text = String(decoding: (try? Data(contentsOf: url)) ?? Data(), as: UTF8.self)
        #expect(text.components(separatedBy: "\r\n").filter { !$0.isEmpty }.count == 2)
        #expect(text.contains("Ana"))
        #expect(!text.contains("Bia"))
    }

    // Scenario: Dois inquéritos em XML
    @Test func doisInqueritosEmXmlExportaAmbos() throws {
        let first = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        let second = try SurveyFixtures.insertSurvey(db, name: "Escola B")
        model.selectedSurveyIDs = [first, second]
        let url = directory.appendingPathComponent("inqueritos.xml")
        #expect(try model.export(format: .xml, to: url) == nil)
        let doc = try? XMLDocument(contentsOf: url)
        #expect(try doc?.nodes(forXPath: "/Surveys/Survey").count == 2)
    }
}
