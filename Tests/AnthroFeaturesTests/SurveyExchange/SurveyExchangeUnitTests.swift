import AnthroCore
import AnthroFeatures
import AnthroIO
import AnthroStore
import Foundation
import Testing

/// Laço interno da importação e exportação do inquérito: adaptador, modelo e rascunho no editor.
@MainActor
@Suite("survey-data-exchange: adaptador, modelo e rascunho (unitários)")
struct SurveyExchangeUnitTests {
    let db: AnthroDatabase
    let exchange: RepositorySurveyExchange
    let presenter = RecordingDraftPresenter()
    let model: SurveyExchangeModel
    let directory: URL

    init() throws {
        db = try SurveyFixtures.makeDatabase()
        exchange = RepositorySurveyExchange(database: db, surveys: SurveyRepository(database: db))
        model = SurveyExchangeModel(source: exchange, sink: exchange, presenter: presenter, engine: try AnthroEngine.shared())
        directory = try SurveyExchangeTestFiles.directory()
    }

    private func file(_ name: String, _ text: String) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try Data(text.utf8).write(to: url)
        return url
    }

    // MARK: Adaptador

    @Test func insertAllIgnoresIncomingIDsAndExportReadsBack() throws {
        var record = SurveyRecord(sex: .girl)
        record.id = 999
        record.firstName = "Ana"
        let count = try exchange.insertAll([ExchangeSurvey(survey: Survey(id: 555, name: "Escola A"), records: [record])])
        #expect(count == 1)
        let id = try #require(try SurveyRepository(database: db).list(archived: false).first?.id)
        #expect(id != 555)
        let exported = try exchange.surveysForExport(ids: [id])
        #expect(exported.first?.survey.name == "Escola A")
        #expect(exported.first?.records.map(\.firstName) == ["Ana"])
        #expect(exported.first?.records.first?.id != 999)
    }

    // MARK: Modelo

    @Test func unmappingSexFailsWithMissingFieldMessage() throws {
        model.beginImport(from: try file("a.csv", "Sex;Weight\r\n1;18\r\n"))
        model.setMapping(.sex, column: nil)
        model.confirmMapping()
        guard case .failed(let message) = model.phase else {
            Issue.record("expected failed, got \(model.phase)")
            return
        }
        #expect(message.hasPrefix("Não foi possível importar o arquivo 'a.csv': um ou mais campos obrigatórios estão ausentes."))
        #expect(message.contains("Sex"))
        #expect(presenter.drafts.isEmpty)
    }

    @Test func setMappingChangesTheProposal() throws {
        model.beginImport(from: try file("a.csv", "sexo;Weight\r\n1;18\r\n"))
        model.setMapping(.sex, column: "sexo")
        guard case .mapping(_, let mapping) = model.phase else {
            Issue.record("expected mapping, got \(model.phase)")
            return
        }
        #expect(mapping[.sex] == "sexo")
        model.confirmMapping()
        #expect(presenter.drafts.first?.records.count == 1)
    }

    @Test func unreadableAndEmptyFilesFail() throws {
        model.beginImport(from: directory.appendingPathComponent("nao-existe.csv"))
        guard case .failed(let missing) = model.phase else {
            Issue.record("expected failed, got \(model.phase)")
            return
        }
        #expect(missing == "Não foi possível importar o arquivo 'nao-existe.csv': o arquivo não pôde ser lido.")
        model.beginImport(from: try file("vazio.csv", ""))
        #expect(model.phase == .failed(message: "Não foi possível importar o arquivo 'vazio.csv': o formato do arquivo é inválido."))
    }

    @Test func bothWarningsAreReported() {
        let message = SurveyExchangeModel.warningMessage(rowErrors: [ImportFieldError(line: 3, field: "Sex")], hadFieldWarnings: true,
                                                         fileName: "a.csv")
        #expect(message?.contains("linha 3, campo 'Sex'.") == true)
        #expect(message?.contains("um ou mais campos estavam ausentes ou continham valores inválidos.") == true)
        // `DisplayImportWarningRows`: "Detalhes:" e os itens em sequência, depois de uma linha em branco.
        let rows = SurveyExchangeModel.warningMessage(rowErrors: [ImportFieldError(line: 3, field: "Sex"), ImportFieldError(line: 5, field: "Sex")],
                                                      hadFieldWarnings: false, fileName: "a.csv")
        #expect(rows?.hasSuffix("\n\nDetalhes: linha 3, campo 'Sex'. linha 5, campo 'Sex'.") == true)
        #expect(SurveyExchangeModel.warningMessage(rowErrors: [], hadFieldWarnings: false, fileName: "a.csv") == nil)
    }

    @Test func xmlDatabaseFailureLeavesNothingAndReportsIt() throws {
        try db.execute("CREATE TRIGGER falha BEFORE INSERT ON records BEGIN SELECT RAISE(ABORT, 'falha'); END")
        model.beginImport(from: try file("i.xml", SurveyExchangeTestFiles.twoSurveysXML()))
        guard case .failed(let message) = model.phase else {
            Issue.record("expected failed, got \(model.phase)")
            return
        }
        #expect(message.hasPrefix("Não foi possível importar o arquivo 'i.xml':"))
        #expect(try SurveyExchangeTestFiles.count(db, "surveys") == 0)
    }

    @Test func canExportNeedsASelectionAndResultsFollowTheFlag() throws {
        #expect(!model.canExport)
        let id = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        try SurveyFixtures.insertRecord(db, surveyID: id, position: 0, firstName: "Ana")
        model.selectedSurveyIDs = [id]
        #expect(model.canExport)
        let url = directory.appendingPathComponent("a.txt")
        _ = try model.export(format: .tabText, to: url)
        #expect(!String(decoding: try Data(contentsOf: url), as: UTF8.self).contains("WAZ"))
        model.includeResults = true
        _ = try model.export(format: .tabText, to: url)
        #expect(String(decoding: try Data(contentsOf: url), as: UTF8.self).contains("\tWAZ\tHAZ\tBAZ\tBMI"))
    }

    // MARK: Rascunho no editor

    private func module() throws -> SurveyModuleModel {
        let m = SurveyModuleModel(repository: SurveyRepository(database: db), engine: try AnthroEngine.shared(),
                                  today: { day("2026-10-15") })
        try m.list.reload()
        return m
    }

    private var draft: ExchangeSurvey {
        ExchangeSurvey(survey: Survey(name: "escola_a"), records: [SurveyRecord(sex: .girl), SurveyRecord(sex: .boy)])
    }

    @Test func draftOpensAsUnsavedNewSurvey() throws {
        let m = try module()
        #expect(m.openDraft(draft) == .done)
        let open = try #require(m.openSurvey)
        #expect(open.survey.id == nil)
        #expect(open.name == "escola_a")
        #expect(open.hasUnsavedChanges)
        try open.save()
        #expect(try SurveyExchangeTestFiles.count(db, "records") == 2)
    }

    @Test func draftOverDirtySurveyAsksFirst() throws {
        let a = try SurveyFixtures.insertSurvey(db, name: "Escola A")
        let m = try module()
        _ = try m.open(id: a)
        try #require(m.openSurvey).name = "Escola A revisada"
        #expect(m.openDraft(draft) == .needsDecision)
        #expect(m.pendingAction == .openDraft(draft))
        try m.resolvePending(.discard)
        #expect(m.openSurvey?.name == "escola_a")
        #expect(m.openSurvey?.hasUnsavedChanges == true)
    }

    /// O módulo é o editor que recebe o rascunho da tela de importação.
    @Test func moduleIsTheDraftPresenter() throws {
        let m = try module()
        let exchange = SurveyExchangeModel(source: self.exchange, sink: self.exchange, presenter: m, engine: try AnthroEngine.shared())
        exchange.beginImport(from: try file("escola_b.csv", "Sex;Weight\r\n1;18\r\n"))
        exchange.confirmMapping()
        #expect(m.openSurvey?.name == "escola_b")
        #expect(m.openSurvey?.hasUnsavedChanges == true)
    }

    // MARK: Achados da revisão

    /// XML válido sem `Survey` (o arquivo de crianças, por engano) não anuncia gravação.
    @Test func xmlWithoutSurveysFails() throws {
        model.beginImport(from: try file("criancas.xml", "<?xml version=\"1.0\"?><Children><Child DisplayID=\"1\" /></Children>"))
        #expect(model.phase == .failed(message: "Não foi possível importar o arquivo 'criancas.xml': nenhum inquérito foi encontrado no arquivo."))
    }

    /// Textos cortados na leitura do XML são avisados, como na Avaliação individual.
    @Test func xmlImportWarnsAboutCutTexts() throws {
        let long = String(repeating: "a", count: 60)
        let xml = SurveyExchangeTestFiles.twoSurveysXML().replacingOccurrences(of: "Name=\"Escola B\"", with: "Name=\"\(long)\"")
        model.beginImport(from: try file("i.xml", xml))
        guard case .finished(let warning?) = model.phase else {
            Issue.record("expected a finished phase with a warning, got \(model.phase)")
            return
        }
        #expect(warning.contains("1 texto(s) do arquivo passavam do limite do AnthroPlus e foram cortados."))
        #expect(warning.contains("Survey.Name"))
        #expect(try SurveyExchangeTestFiles.count(db, "surveys") == 2)
    }

    /// O nome do rascunho vem do arquivo, no limite de 50 caracteres do nome do inquérito.
    @Test func draftNameIsCutAtTheSurveyNameLimit() throws {
        model.beginImport(from: try file(String(repeating: "n", count: 60) + ".csv", "Sex\r\n1\r\n"))
        model.confirmMapping()
        #expect(presenter.drafts.first?.survey.name == String(repeating: "n", count: 50))
    }

    /// As colunas extras do rascunho chegam ao banco quando a usuária salva.
    @Test func draftWithExtraColumnsKeepsThemWhenSaved() throws {
        let m = try module()
        let exchange = SurveyExchangeModel(source: self.exchange, sink: self.exchange, presenter: m, engine: try AnthroEngine.shared())
        exchange.beginImport(from: try file("escola_c.csv", "Sex;escola\r\n1;Norte\r\n"))
        exchange.confirmMapping()
        try #require(m.openSurvey).save()
        let survey = try #require(try SurveyFixtures.row(db, "surveys", where: "name = 'escola_c'"))
        guard case .text(let definition) = survey["additional_data_def"] else {
            Issue.record("expected a stored definition, got \(String(describing: survey["additional_data_def"]))")
            return
        }
        #expect(definition.contains("escola"))
        guard case .text(let values) = try SurveyFixtures.row(db, "records", where: "1 = 1")?["additional_data"] else {
            Issue.record("expected stored values")
            return
        }
        #expect(values.contains("Norte"))
    }

    /// Salvar o aberto falha (sem nome): o rascunho não substitui o inquérito aberto e a pendência some.
    @Test func failedSaveBeforeTheDraftKeepsTheOpenSurvey() throws {
        let m = try module()
        _ = m.createSurvey()
        try #require(m.openSurvey).name = "   "
        #expect(m.openDraft(draft) == .needsDecision)
        #expect(throws: (any Error).self) { try m.resolvePending(.save) }
        #expect(m.pendingAction == nil)
        #expect(m.openSurvey?.survey.id == nil)
        #expect(m.openSurvey?.name == "   ")
    }
}
