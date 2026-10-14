import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Cenários do XML de crianças: exportação, importação e ida e volta (change add-individual-import-export).
@Suite("individual-data-exchange: XML de crianças")
struct ChildXMLTests {
    private typealias F = ExchangeFixtures

    private func document(_ data: Data) throws -> XMLDocument {
        try #require(try? XMLDocument(data: data))
    }

    private func attributeNames(_ node: XMLNode?) -> [String] {
        ((node as? XMLElement)?.attributes ?? []).compactMap(\.name)
    }

    // MARK: Exportação

    // Scenario: Criança completa com uma visita
    @Test func criancaCompletaComUmaVisitaTemElementosEAtributos() throws {
        let results = ExchangeResults(weightForAgeZ: d("-0.5"), lengthOrHeightForAgeZ: d("0.12"), bmiForAgeZ: d("-1"), bmi: d("15.2"))
        let child = F.ana(mother: ExchangePerson(firstName: "Maria"), address: ExchangeAddress(place: "São Paulo"),
                          visits: [F.visit("2021-04-01", weight: "18.4", height: "110", results: results)])
        let doc = try document(ChildXML.data([child], includeResults: true))
        #expect(try doc.nodes(forXPath: "/Children/Child/Mother").count == 1)
        #expect(try doc.nodes(forXPath: "/Children/Child/Address").count == 1)
        #expect(try doc.nodes(forXPath: "/Children/Child/Father").count == 0)
        let visits = try doc.nodes(forXPath: "/Children/Child/Visits/Visit")
        #expect(visits.count == 1)
        #expect(attributeNames(visits.first) == ["Date", "Weight", "Height", "IsRecumbent", "HasOedema", "Notes", "AdditionalData",
                                                 "CreatedBy", "WAZ", "HAZ", "BAZ", "BMI"])
    }

    // Scenario: Criança sem visitas no XML
    @Test func criancaSemVisitasNoXmlNaoTemFilhos() throws {
        let doc = try document(ChildXML.data([F.ana()], includeResults: false))
        let children = try doc.nodes(forXPath: "/Children/Child")
        #expect(children.count == 1)
        #expect(children.first?.childCount == 0)
    }

    // Scenario: Visita sem dados adicionais no XML
    @Test func visitaSemDadosAdicionaisNoXmlTemAtributoVazio() throws {
        let doc = try document(ChildXML.data([F.ana(visits: [F.visit("2021-04-01", weight: "18")])], includeResults: false))
        let visit = try doc.nodes(forXPath: "/Children/Child/Visits/Visit").first as? XMLElement
        #expect(visit?.attribute(forName: "AdditionalData")?.stringValue == "<Data />")
    }

    // MARK: Leitura de valores e datas

    // Scenario: Sexo não reconhecido
    @Test func sexoNaoReconhecidoRejeitaOArquivo() {
        expectInvalidStructure(F.xml(F.child(["Sex": "x"])))
    }

    // Scenario: Data ilegível
    @Test func dataIlegivelRejeitaOArquivo() {
        expectInvalidStructure(F.xml(F.child(["DateOfBirth": "março de 2016"])))
    }

    // MARK: Truncamento

    // Scenario: Nome longo e peso com três casas
    @Test func nomeLongoEPesoComTresCasasSaoTruncados() throws {
        let longName = String(repeating: "Ana Beatriz ", count: 5)
        let children = try ChildXML.read(F.xml(F.child(["FirstName": longName],
                                                       inner: F.visits(F.visitXML("01-04-2021 00:00:00", ["Weight": "16.789"])))))
        let child = try #require(children.first)
        #expect(child.firstName == String(longName.prefix(50)))
        #expect(child.visits.first?.weight == d("16.78"))
    }

    // Scenario: Truncamento leva o peso abaixo do mínimo
    @Test func truncamentoLevaOPesoAbaixoDoMinimoERejeita() {
        expectInvalidStructure(F.xml(F.child(inner: F.visits(F.visitXML("01-04-2021 00:00:00", ["Weight": "0.899"])))))
    }

    // MARK: Obrigatórios e limites

    // Scenario: Visita antes do nascimento
    @Test func visitaAntesDoNascimentoRejeita() {
        expectInvalidStructure(F.xml(F.child(inner: F.visits(F.visitXML("14-03-2016 00:00:00")))))
    }

    // Scenario: Visita na data do nascimento
    @Test func visitaNaDataDoNascimentoEhAceita() throws {
        let children = try ChildXML.read(F.xml(F.child(inner: F.visits(F.visitXML("15-03-2016 00:00:00")))))
        #expect(children.count == 1)
        #expect(children.first?.visits.count == 1)
        #expect(ymd(children.first?.visits.first?.date) == "2016-03-15")
    }

    // Scenario: Atributo opcional ausente
    @Test func atributoOpcionalAusenteEhAceitoComoNil() throws {
        let children = try ChildXML.read(F.xml(F.child(["Notes": nil, "DisplayID": nil])))
        #expect(children.count == 1)
        #expect(children.first?.notes == nil)
        #expect(children.first?.displayID == nil)
        #expect(children.first?.firstName == "Ana")
    }

    // MARK: Datas de visita

    // Scenario: Duas visitas na mesma data
    @Test func duasVisitasNaMesmaDataRejeitaComValorInvalido() {
        let data = F.xml(F.child(inner: F.visits(F.visitXML("01-04-2021 00:00:00"), F.visitXML("01-04-2021 00:00:00"))))
        #expect(throws: ImportFailure.invalidFieldValue([])) { try ChildXML.read(data) }
    }

    // Scenario: Visitas fora de ordem
    @Test func visitasForaDeOrdemRejeitaComValorInvalido() {
        let data = F.xml(F.child(inner: F.visits(F.visitXML("01-10-2021 00:00:00"), F.visitXML("01-04-2021 00:00:00"))))
        #expect(throws: ImportFailure.invalidFieldValue([])) { try ChildXML.read(data) }
    }

    // Scenario: Visitas em ordem crescente
    @Test func visitasEmOrdemCrescenteSaoAceitas() throws {
        let data = F.xml(F.child(inner: F.visits(F.visitXML("01-04-2021 00:00:00"), F.visitXML("01-10-2021 00:00:00"))))
        let children = try ChildXML.read(data)
        #expect(children.first?.visits.map { ymd($0.date) } == ["2021-04-01", "2021-10-01"])
    }

    // MARK: Dados adicionais

    // Scenario: Dados adicionais válidos
    @Test func dadosAdicionaisValidosSaoGuardados() throws {
        let value = "&lt;Data&gt;&lt;Cat ID=&quot;Food&quot; Descr=&quot;&quot; /&gt;&lt;/Data&gt;"
        let children = try ChildXML.read(F.xml(F.child(inner: F.visits(F.visitXML("01-04-2021 00:00:00", ["AdditionalData": value])))))
        let visit = try #require(children.first?.visits.first)
        #expect(visit.additionalData?.sections.map(\.identifier) == ["Food"])
    }

    // Scenario: Dados adicionais malformados
    @Test func dadosAdicionaisMalformadosRejeitam() {
        expectInvalidStructure(F.xml(F.child(inner: F.visits(F.visitXML("01-04-2021 00:00:00", ["AdditionalData": "&lt;Data&gt;&lt;Cat&gt;"])))))
    }

    // MARK: Campos sem destino no app

    // Scenario: CreatedBy e SALB lidos e descartados
    @Test func createdByESalbLidosSaoDescartados() throws {
        let address = "<Address StreetInfo=\"\" Place=\"São Paulo\" ZIP=\"\" District=\"\" Province=\"\" State=\"\" Country=\"\" SALBLevel1=\"123\" SALBLevel2=\"\" PhoneNumber=\"\" Email=\"\" CreatedBy=\"obs1\" />"
        let mother = "<Mother FirstName=\"Maria\" LastName=\"\" Height=\"\" Weight=\"\" DateOfBirth=\"\" DateOfBirthIsApprox=\"0\" Notes=\"\" CreatedBy=\"obs1\" />"
        let children = try ChildXML.read(F.xml(F.child(inner: mother + address + F.visits(F.visitXML("01-04-2021 00:00:00")))))
        #expect(children.count == 1)
        let doc = try document(ChildXML.data(children, includeResults: false))
        let createdBy = try doc.nodes(forXPath: "//@CreatedBy").map(\.stringValue)
        #expect(createdBy.count == 4)
        #expect(createdBy.allSatisfy { $0 == "AnthroPlus" })
        #expect(try doc.nodes(forXPath: "/Children/Child/Address/@SALBLevel1").first?.stringValue == "")
    }

    // MARK: Ida e volta

    // Scenario: Exportar e reimportar
    @Test func exportarEReimportarPreservaTodosOsCampos() throws {
        let school = AdditionalData(sections: [AdditionalDataSection(identifier: "Escola", variables: [
            AdditionalDataVariable(identifier: "Série", kind: .text("3º ano")),
            AdditionalDataVariable(identifier: "Recreio", kind: .number(value: d("2.5"), minimum: 0, maximum: 10)),
        ])])
        let mother = ExchangePerson(firstName: "Maria", lastName: "Silva", height: d("162.5"), weight: d("61.2"),
                                    dateOfBirth: day("1985-05-02"), dateOfBirthIsApprox: true, notes: "mãe")
        let father = ExchangePerson(firstName: "João", lastName: "Silva", height: d("175"), dateOfBirth: day("1983-01-10"))
        let address = ExchangeAddress(streetInfo: "Rua Botucatu, 740", place: "São Paulo", zip: "04023-062",
                                      district: "Vila Clementino", province: "SP", state: "SP", country: "Brasil",
                                      phoneNumber: "11 5555-0000", email: "ana@example.org")
        let children = [
            F.ana(notes: "observação \"com aspas\" & <sinais>", mother: mother, father: father, address: address,
                  visits: [F.visit("2021-04-01", weight: "18.4", height: "110.25", notes: "manhã", additionalData: school),
                           F.visit("2021-10-01", weight: "19", height: "112", oedema: true, additionalData: AdditionalData())]),
            ExchangeChild(displayID: nil, firstName: "Bia", dateOfBirth: day("2020-02-29"), dateOfBirthIsApprox: true, sex: .boy,
                          visits: [F.visit("2020-06-01", weight: "6.25", height: "61.5", recumbent: true, additionalData: AdditionalData())]),
            ExchangeChild(displayID: 3, lastName: "Souza", dateOfBirth: day("2015-12-31"), sex: .girl, mother: ExchangePerson()),
        ]
        let reread = try ChildXML.read(ChildXML.data(children, includeResults: false))
        #expect(reread == children)
    }

    // Scenario: Arquivo no layout do original com vírgula decimal
    @Test func arquivoNoLayoutDoOriginalComVirgulaDecimalEhLido() throws {
        let children = try ChildXML.read(try F.fixture("ia-original-ptbr.xml"))
        let child = try #require(children.first)
        #expect(child.displayID == 12)
        #expect(child.visits.first?.weight == d("16.5"))
        #expect(child.visits.first?.height == d("110.2"))
        #expect(child.mother?.height == d("162.5"))
        #expect(child.address?.place == "São Paulo")
    }
}
