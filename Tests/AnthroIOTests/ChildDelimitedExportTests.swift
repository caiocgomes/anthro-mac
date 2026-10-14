import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Cenários da exportação TXT e CSV de crianças (change add-individual-import-export).
@Suite("individual-data-exchange: exportação delimitada")
struct ChildDelimitedExportTests {
    private func export(_ children: [ExchangeChild], definition: AdditionalData = AdditionalData(),
                        results: Bool = false, format: DelimitedFormat) -> Data {
        ChildDelimitedExport.data(children, additionalDefinition: definition, includeResults: results, format: format)
    }

    private let other = ExchangeChild(displayID: 13, firstName: "Bia", dateOfBirth: day("2017-01-20"), sex: .girl)

    // Scenario: Cabeçalho sem resultados
    @Test func cabecalhoSemResultadosTem43ColunasNaOrdemOriginal() {
        let table = ExchangeFixtures.table(export([ExchangeFixtures.ana(), other], format: .semicolonCSV), separator: ";")
        let header = table.first ?? []
        #expect(header.count == 43)
        #expect(header.prefix(9).joined(separator: ";")
            == "DisplayID;FirstName;LastName;DateOfBirth;DateOfBirthIsApprox;Sex;ChildNotes;ChildCreatedBy;MotherFirstName")
        #expect(header.suffix(7).joined(separator: ";") == "Date;Weight;Height;IsRecumbent;HasOedema;Notes;CreatedBy")
    }

    // Scenario: Cabeçalho com resultados
    @Test func cabecalhoComResultadosAcrescentaWazHazBazBmi() {
        let table = ExchangeFixtures.table(export([ExchangeFixtures.ana(), other], results: true, format: .semicolonCSV),
                                           separator: ";")
        let header = table.first ?? []
        #expect(header.count == 47)
        #expect(Array(header.suffix(4)) == ["WAZ", "HAZ", "BAZ", "BMI"])
        #expect(header.count < 43 || header[42] == "CreatedBy")
    }

    // Scenario: Criança com três visitas
    @Test func criancaComTresVisitasGeraTresLinhasRepetindoDados() {
        let child = ExchangeFixtures.ana(visits: [ExchangeFixtures.visit("2021-04-01", weight: "18"),
                                                  ExchangeFixtures.visit("2021-10-01", weight: "19"),
                                                  ExchangeFixtures.visit("2022-04-01", weight: "20")])
        let table = ExchangeFixtures.table(export([child], format: .tabText), separator: "\t")
        #expect(table.count == 4)
        #expect((0..<3).map { ExchangeFixtures.cell(table, "FirstName", row: $0) } == ["Ana", "Ana", "Ana"])
        #expect((0..<3).map { ExchangeFixtures.cell(table, "Weight", row: $0) } == ["18", "19", "20"])
    }

    // Scenario: Criança sem visitas
    @Test func criancaSemVisitasGeraUmaLinhaComVisitaVazia() {
        let table = ExchangeFixtures.table(export([ExchangeFixtures.ana()], format: .tabText), separator: "\t")
        #expect(table.count == 2)
        #expect(ExchangeFixtures.cell(table, "FirstName") == "Ana")
        #expect(["Date", "Weight", "Height"].map { ExchangeFixtures.cell(table, $0) } == ["", "", ""])
    }

    // Scenario: Valor com o separador no CSV
    @Test func valorComOSeparadorNoCsvVaiEntreAspasComBom() {
        let data = export([ExchangeFixtures.ana(notes: "pesada; sem sapatos")], format: .semicolonCSV)
        #expect(Array(data.prefix(3)) == [0xEF, 0xBB, 0xBF])
        #expect(String(decoding: data, as: UTF8.self).contains(";\"pesada; sem sapatos\";"))
    }

    // Scenario: Altura da mãe ausente
    @Test func alturaDaMaeAusenteSaiVazia() {
        let child = ExchangeFixtures.ana(mother: ExchangePerson(firstName: "Maria", weight: d("61.2")))
        let table = ExchangeFixtures.table(export([child], format: .semicolonCSV), separator: ";")
        #expect(ExchangeFixtures.cell(table, "MotherFirstName") == "Maria")
        #expect(ExchangeFixtures.cell(table, "MotherHeight") == "")
        #expect(ExchangeFixtures.cell(table, "MotherWeight") == "61,2")
    }

    // Scenario: Colisões de nome com colunas fixas
    @Test func colisoesDeNomeComColunasFixasRecebemSufixo() {
        let definition = AdditionalData(sections: [
            AdditionalDataSection(identifier: "A", variables: [AdditionalDataVariable(identifier: "Sport", kind: .number(value: nil, minimum: nil, maximum: nil))]),
            AdditionalDataSection(identifier: "B", variables: [
                AdditionalDataVariable(identifier: "Sport", kind: .text(nil)),
                AdditionalDataVariable(identifier: "Weight", kind: .number(value: nil, minimum: nil, maximum: nil)),
            ]),
        ])
        let table = ExchangeFixtures.table(export([ExchangeFixtures.ana()], definition: definition, results: true,
                                                  format: .tabText), separator: "\t")
        #expect(Array((table.first ?? []).suffix(3)) == ["Sport", "Sport 2", "Weight 2"])
        #expect(table.first?.count == 50)
    }

    // Scenario: Visita sem dados adicionais
    @Test func visitaSemDadosAdicionaisDeixaColunasVazias() {
        let definition = AdditionalData(sections: [AdditionalDataSection(identifier: "Escola", variables: [
            AdditionalDataVariable(identifier: "Sport", kind: .number(value: nil, minimum: nil, maximum: nil)),
            AdditionalDataVariable(identifier: "Série", kind: .text(nil)),
        ])])
        let child = ExchangeFixtures.ana(visits: [ExchangeFixtures.visit("2021-04-01", weight: "18")])
        let table = ExchangeFixtures.table(export([child], definition: definition, format: .tabText), separator: "\t")
        #expect(table.first?.count == 45)
        #expect(ExchangeFixtures.cell(table, "Sport") == "")
        #expect(ExchangeFixtures.cell(table, "Série") == "")
        #expect(table.dropFirst().first?.count == 45)
    }

    // Scenario: CreatedBy e SALB na exportação
    @Test func createdByESalbNaExportacaoSaoFixos() {
        let child = ExchangeFixtures.ana(mother: ExchangePerson(firstName: "Maria"), address: ExchangeAddress(place: "São Paulo"),
                                         visits: [ExchangeFixtures.visit("2021-04-01", weight: "18")])
        let table = ExchangeFixtures.table(export([child], format: .semicolonCSV), separator: ";")
        #expect(["ChildCreatedBy", "MotherCreatedBy", "AddressCreatedBy", "CreatedBy"].map { ExchangeFixtures.cell(table, $0) }
            == ["AnthroPlus", "AnthroPlus", "AnthroPlus", "AnthroPlus"])
        #expect(["AddressSALBLevel1", "AddressSALBLevel2"].map { ExchangeFixtures.cell(table, $0) } == ["", ""])
    }
}
