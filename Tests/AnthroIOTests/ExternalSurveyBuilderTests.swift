import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Cenários da montagem do inquérito importado de arquivo externo (change add-survey-import-export).
@Suite("survey-data-exchange: montagem do inquérito importado")
struct ExternalSurveyBuilderTests {
    private typealias F = SurveyExchangeFixtures

    private func build(_ table: ImportedTable, _ mapping: [SurveyImportField: String]) throws(ImportFailure) -> ExternalImportResult {
        try ExternalSurveyBuilder.build(table: table, mapping: mapping, name: "escola_a")
    }

    // Scenario: Sexo não mapeado
    @Test func sexoNaoMapeadoFalhaComCampoAusente() {
        let table = F.table(["Weight", "Height"], [["18", "110"]])
        #expect(throws: ImportFailure.missingField([ImportFieldError(line: 0, field: "Sex")])) {
            try build(table, [.weight: "Weight", .height: "Height"])
        }
    }

    // Scenario: Sexo mapeado
    @Test func sexoMapeadoMontaTodosOsRegistros() throws {
        let result = try build(F.table(["Sex"], [["1"], ["2"], ["0"]]), [.sex: "Sex"])
        #expect(result.draft.records.count == 3)
        #expect(result.draft.survey.name == "escola_a")
    }

    // Scenario: Doze registros com sexo inválido
    @Test func dozeRegistrosComSexoInvalidoListamDez() throws {
        let rows = (1...20).map { [(3...14).contains($0) ? "x" : "1"] }
        let result = try build(F.table(["sexo"], rows), [.sex: "sexo"])
        #expect(result.draft.records.count == 8)
        #expect(result.rowErrors.count == 10)
        #expect(result.rowErrors.first == ImportFieldError(line: 3, field: "sexo"))
    }

    // Scenario: Sexo com código 2
    @Test func sexoComCodigoDoisEhMenina() throws {
        let result = try build(F.table(["Sex"], [["2"]]), [.sex: "Sex"])
        #expect(result.draft.records.map(\.sex) == [.girl])
    }

    // Scenario: Data de visita inválida
    @Test func dataDeVisitaInvalidaMantemRegistroComAviso() throws {
        let result = try build(F.table(["Sex", "Data"], [["1", "31/02/2021"]]), [.sex: "Sex", .date: "Data"])
        #expect(result.draft.records.count == 1)
        #expect(result.draft.records.first?.visitDate == nil)
        #expect(result.hadFieldWarnings)
    }

    // Scenario: Fator de ponderação vazio e sem mapeamento
    @Test func fatorDePonderacaoVazioViraZeroESemMapeamentoUm() throws {
        let table = F.table(["Sex", "Fator"], [["1", ""]])
        let mapped = try build(table, [.sex: "Sex", .weightingFactor: "Fator"])
        #expect(mapped.draft.records.first?.weightingFactor == 0)
        #expect(mapped.hadFieldWarnings)
        let unmapped = try build(table, [.sex: "Sex"])
        #expect(unmapped.draft.records.first?.weightingFactor == 1)
        #expect(!unmapped.hadFieldWarnings)
    }

    // Scenario: Edema não informado
    @Test func edemaNaoInformadoViraFalso() throws {
        let result = try build(F.table(["Sex", "Edema"], [["1", ""]]), [.sex: "Sex", .hasOedema: "Edema"])
        #expect(result.draft.records.first?.hasOedema == false)
    }

    // Scenario: Peso com três casas
    @Test func pesoComTresCasasEhTruncado() throws {
        let result = try build(F.table(["Sex", "Weight"], [["1", "16.789"]]), [.sex: "Sex", .weight: "Weight"])
        #expect(result.draft.records.first?.weight == d("16.78"))
    }

    // Scenario: Peso abaixo do mínimo
    @Test func pesoAbaixoDoMinimoFicaAusenteComAviso() throws {
        let result = try build(F.table(["Sex", "Weight"], [["1", "0.89"]]), [.sex: "Sex", .weight: "Weight"])
        #expect(result.draft.records.count == 1)
        #expect(result.draft.records.first?.weight == nil)
        #expect(result.hadFieldWarnings)
    }

    // Scenario: Idade abaixo de 731 dias
    @Test func idadeAbaixoDe731DiasMarcaDeitado() throws {
        let result = try build(F.table(["Sex", "Age"], [["1", "23.9"]]), [.sex: "Sex", .ageInMonths: "Age"])
        #expect(result.draft.records.first?.measuredRecumbent == true)
        #expect(result.draft.records.first?.ageInMonths == d("23.9"))
    }

    // Scenario: Sem idade e com altura de corte
    @Test func semIdadeComAlturaDeCorteDecidePorOitentaESete() throws {
        let result = try build(F.table(["Sex", "Height"], [["1", "86.9"], ["1", "87.0"]]), [.sex: "Sex", .height: "Height"])
        #expect(result.draft.records.map(\.measuredRecumbent) == [true, false])
    }

    // Scenario: Sem idade e sem altura
    @Test func semIdadeESemAlturaMarcaEmPe() throws {
        let result = try build(F.table(["Sex"], [["1"]]), [.sex: "Sex"])
        #expect(result.draft.records.map(\.measuredRecumbent) == [false])
    }

    // Scenario: Duas colunas extras
    @Test func duasColunasExtrasViramVariaveisImportadas() throws {
        let result = try build(F.table(["Sex", "escola", "turma"], [["1", "Escola A", "3º ano"], ["2", "Escola B", "4º ano"]]),
                               [.sex: "Sex"])
        let definition = try AdditionalDataXML.decode(result.draft.survey.additionalDataDefinitionXML)
        #expect(definition.sections.map(\.identifier) == ["Imported"])
        #expect(definition.sections.first?.variables == [AdditionalDataVariable(identifier: "escola", kind: .text(nil)),
                                                         AdditionalDataVariable(identifier: "turma", kind: .text(nil))])
        let values = try result.draft.records.map { try AdditionalDataXML.decode($0.additionalDataXML) }
        #expect(values.map { $0.variable(section: "Imported", variable: "turma")?.kind } == [.text("3º ano"), .text("4º ano")])
        #expect(values.first?.variable(section: "Imported", variable: "escola")?.kind == .text("Escola A"))
    }

    // Scenario: Todas as colunas mapeadas
    @Test func todasAsColunasMapeadasNaoCriamVariaveis() throws {
        let result = try build(F.table(["Sex", "Weight"], [["1", "18"], ["2", "19"]]), [.sex: "Sex", .weight: "Weight"])
        #expect(result.draft.records.count == 2)
        #expect(result.draft.survey.additionalDataDefinitionXML == nil)
        #expect(result.draft.records.allSatisfy { $0.additionalDataXML == nil })
    }

    // Scenario: Planilha com as duas datas e a idade
    @Test func idadeComAsDuasDatasEhDescartadaNaPlanilha() throws {
        let result = try build(F.table(["Data", "Nasc", "Idade", "Sex"], [["01/04/2021", "15/03/2016", "70", "1"]]),
                               [.date: "Data", .dateOfBirth: "Nasc", .ageInMonths: "Idade", .sex: "Sex"])
        let record = try #require(result.draft.records.first)
        #expect(ymd(record.visitDate) == "2021-04-01")
        #expect(ymd(record.dateOfBirth) == "2016-03-15")
        #expect(record.ageInMonths == nil)
    }
}
