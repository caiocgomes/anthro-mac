import AnthroIO
import Testing

/// Cenários da proposta automática de mapeamento (change add-survey-import-export).
@Suite("survey-data-exchange: proposta de mapeamento")
struct ColumnAutoMapperTests {
    // Scenario: Colunas usuais
    @Test func colunasUsuaisSaoMapeadasAutomaticamente() {
        #expect(ColumnAutoMapper.propose(columns: ["ID", "Sex", "Weight_kg", "Length", "Oedema", "escola"])
            == [.displayID: "ID", .sex: "Sex", .weight: "Weight_kg", .height: "Length", .hasOedema: "Oedema"])
    }

    // Scenario: Fator de ponderação sem espaço
    @Test func fatorDePonderacaoSemEspacoViraPeso() {
        let proposal = ColumnAutoMapper.propose(columns: ["WT FACTOR", "WEIGHTFACTOR"])
        #expect(proposal[.weightingFactor] == "WT FACTOR")
        #expect(proposal[.weight] == "WEIGHTFACTOR")
    }

    // Scenario: Duas colunas para o mesmo campo
    @Test func duasColunasParaOMesmoCampoUltimaVence() {
        #expect(ColumnAutoMapper.propose(columns: ["weight1", "weight2"])[.weight] == "weight2")
    }
}
