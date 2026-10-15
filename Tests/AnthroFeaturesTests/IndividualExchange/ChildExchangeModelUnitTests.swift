import AnthroCore
import AnthroFeatures
import AnthroIO
import AnthroStore
import Foundation
import Testing

@MainActor
@Suite("individual-data-exchange: modelo da tela (unitários)")
struct ChildExchangeModelUnitTests {
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
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("anthro-exchange-unit", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    @Test func messagesCoverEveryFailureAndPartialDetail() {
        typealias M = ChildExchangeModel
        #expect(M.message(for: .missingField([]), fileName: "a.xml")
            == "Não foi possível importar o arquivo 'a.xml': um ou mais campos obrigatórios estão ausentes.")
        #expect(M.message(for: .invalidStructure(nil), fileName: "a.xml")
            == "Não foi possível importar o arquivo 'a.xml': o formato do arquivo é inválido.")
        #expect(M.message(for: .invalidStructure(ImportFailureDetail(line: 4, element: nil, attribute: nil)), fileName: "a.xml")
            == "Não foi possível importar o arquivo 'a.xml': o formato do arquivo é inválido. Detalhe: linha 4.")
        #expect(M.message(for: .invalidStructure(ImportFailureDetail(line: 7, element: "Visit", attribute: "Weight")), fileName: "a.xml")
            == "Não foi possível importar o arquivo 'a.xml': o formato do arquivo é inválido. Detalhe: linha 7, elemento Visit, atributo Weight.")
    }

    @Test func formatsHaveTheirExtensions() {
        #expect(ChildExportFormat.allCases.map(\.fileExtension) == ["xml", "txt", "csv"])
    }

    @Test func reportIsWrittenAsUTF16WithSuggestedName() throws {
        let id = try IAFixtures.insertChild(db, firstName: "Ana", lastName: "Silva")
        #expect(try model.suggestedReportFileName(childID: id) == "Silva, Ana.txt")
        let url = directory.appendingPathComponent("relatorio.txt")
        try model.writeReport(childID: id, to: url)
        #expect(Array(try Data(contentsOf: url).prefix(2)) == [0xFF, 0xFE])
    }

    @Test func importOfValidFileReportsCountAndUnreadableFileFails() throws {
        let url = directory.appendingPathComponent("ok.xml")
        try Data(#"<?xml version="1.0" encoding="utf-8"?><Children><Child DisplayID="1" FirstName="Ana" DateOfBirth="15-03-2016 00:00:00" DateOfBirthIsApprox="0" Sex="0" /></Children>"#.utf8).write(to: url)
        #expect(model.importXML(from: url) == .imported(count: 1))
        let missing = directory.appendingPathComponent("nao-existe.xml")
        guard case .failed(let message) = model.importXML(from: missing) else {
            Issue.record("expected .failed for a missing file")
            return
        }
        #expect(message.hasPrefix("Não foi possível importar o arquivo 'nao-existe.xml':"))
    }

    @Test func exportWithResultsAddsResultColumns() throws {
        let id = try IAFixtures.insertChild(db, firstName: "Ana")
        model.selectedChildIDs = [id]
        model.includeResults = true
        let url = directory.appendingPathComponent("criancas.txt")
        try model.export(format: .tabText, to: url)
        let header = String(decoding: try Data(contentsOf: url), as: UTF8.self).components(separatedBy: "\r\n").first ?? ""
        #expect(header.hasSuffix("WAZ\tHAZ\tBAZ\tBMI\tMenarche/spermarche\tSelf-reported\tSport\tTV/computer\tFruit&veg portions / day\tBlood pressure\tBlood lipids"))
    }
}
