import AnthroCore
import AnthroFeatures
import AnthroIO
import AnthroStore
import Foundation
import Testing

/// Cenários do modelo da tela de importação e exportação (change add-individual-import-export).
@MainActor
@Suite("individual-data-exchange: modelo da tela")
struct ChildExchangeModelTests {
    let db: AnthroDatabase
    let model: ChildExchangeModel
    let directory: URL

    init() throws {
        db = try IAFixtures.makeDatabase()
        let exchange = RepositoryChildExchange(database: db, children: ChildRepository(database: db),
                                               visits: VisitRepository(database: db), parents: ParentRepository(database: db),
                                               addresses: AddressRepository(database: db),
                                               templates: AdditionalDataTemplateRepository(database: db),
                                               engine: try AnthroEngine.shared())
        model = ChildExchangeModel(source: exchange, sink: exchange)
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("anthro-exchange-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func childCount() throws -> Int64 {
        guard case .integer(let n) = try db.query("SELECT COUNT(*) AS n FROM children").first?["n"] else { return -1 }
        return n
    }

    /// Grava um XML de importação com o nome dado e devolve a URL.
    private func file(_ name: String, _ lines: [String]) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try Data(lines.joined(separator: "\n").utf8).write(to: url)
        return url
    }

    private static let header = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>"

    private static func child(_ id: Int, _ name: String) -> String {
        "<Child DisplayID=\"\(id)\" FirstName=\"\(name)\" LastName=\"\" DateOfBirth=\"15-03-2016 00:00:00\" DateOfBirthIsApprox=\"0\" Sex=\"0\" Notes=\"\" CreatedBy=\"obs1\">"
    }

    private static func visit(_ date: String, weight: String) -> String {
        "<Visit Date=\"\(date) 00:00:00\" Weight=\"\(weight)\" Height=\"110\" IsRecumbent=\"0\" HasOedema=\"0\" Notes=\"\" AdditionalData=\"&lt;Data /&gt;\" CreatedBy=\"obs1\" />"
    }

    // Scenario: Exportação só com criança marcada
    @Test func exportacaoSoComCriancaMarcadaEResultadosDesligados() throws {
        let id = try IAFixtures.insertChild(db, firstName: "Ana")
        #expect(!model.includeResults)
        #expect(!model.canExport)
        model.selectedChildIDs = [id]
        #expect(model.canExport)
    }

    // Scenario: Duas crianças marcadas em CSV
    @Test func duasCriancasMarcadasEmCsvGeramTresLinhas() throws {
        let ana = try IAFixtures.insertChild(db, firstName: "Ana")
        _ = try IAFixtures.insertChild(db, firstName: "Fora")
        let bia = try IAFixtures.insertChild(db, firstName: "Bia")
        model.selectedChildIDs = [ana, bia]
        let url = directory.appendingPathComponent("criancas.csv")
        try model.export(format: .semicolonCSV, to: url)
        let text = String(decoding: (try? Data(contentsOf: url)) ?? Data(), as: UTF8.self)
        let lines = text.components(separatedBy: "\r\n").filter { !$0.isEmpty }
        #expect(lines.count == 3)
        // 43 colunas fixas seguidas das 7 do modelo padrão de dados adicionais, que a migração 4 grava.
        let header = (lines.first.map { $0.hasPrefix("\u{FEFF}") ? String($0.dropFirst()) : $0 } ?? "")
            .split(separator: ";", omittingEmptySubsequences: false).map(String.init)
        #expect(header.count == 50)
        #expect(header.first == "DisplayID")
        #expect(header.count < 43 || header[42] == "CreatedBy")
        #expect(Array(header.suffix(7)) == ["Menarche/spermarche", "Self-reported", "Sport", "TV/computer",
                                            "Fruit&veg portions / day", "Blood pressure", "Blood lipids"])
        #expect(!text.contains("Fora"))
    }

    // Scenario: Peso acima do limite
    @Test func pesoAcimaDoLimiteRejeitaSemGravar() throws {
        let url = try file("criancas.xml", [Self.header, "<Children>",
                                            Self.child(7, "Ana"), "<Visits>", Self.visit("01-04-2021", weight: "18"), "</Visits>", "</Child>",
                                            Self.child(9, "Bia"), "<Visits>", Self.visit("01-04-2021", weight: "300"), "</Visits>", "</Child>",
                                            "</Children>"])
        let outcome = model.importXML(from: url)
        guard case .failed = outcome else {
            Issue.record("expected .failed, got \(outcome)")
            return
        }
        #expect(try childCount() == 0)
    }

    // Scenario: Mensagem de formato inválido
    @Test func mensagemDeFormatoInvalidoTrazDetalhe() throws {
        // O Visit com peso acima do limite está na linha 7 do arquivo.
        let url = try file("criancas.xml", [Self.header, "<Children>", Self.child(7, "Ana"), "<Visits>",
                                            Self.visit("01-04-2021", weight: "18"), Self.visit("01-10-2021", weight: "19"),
                                            Self.visit("01-04-2022", weight: "300"), "</Visits>", "</Child>", "</Children>"])
        guard case .failed(let message) = model.importXML(from: url) else {
            Issue.record("expected .failed")
            return
        }
        #expect(message.hasPrefix("Não foi possível importar o arquivo 'criancas.xml': o formato do arquivo é inválido."))
        #expect(message.contains("linha 7"))
        #expect(message.contains("Visit"))
        #expect(message.contains("Weight"))
    }

    // Scenario: Mensagem de valor inválido
    @Test func mensagemDeValorInvalidoEmPtBr() throws {
        let url = try file("criancas.xml", [Self.header, "<Children>", Self.child(7, "Ana"), "<Visits>",
                                            Self.visit("01-10-2021", weight: "18"), Self.visit("01-04-2021", weight: "19"),
                                            "</Visits>", "</Child>", "</Children>"])
        #expect(model.importXML(from: url)
            == .failed(message: "Não foi possível importar o arquivo 'criancas.xml': um ou mais campos obrigatórios contêm valores inválidos."))
    }
}
