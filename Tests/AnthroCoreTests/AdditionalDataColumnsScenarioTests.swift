import AnthroCore
import Testing

/// Títulos em pt-BR das 19 colunas fixas da tabela do inquérito, escritos por extenso.
let fixedSurveyColumnTitles = ["Data da pesquisa", "Conglomerado", "Equipe", "ID", "Domicílio", "Sexo",
                               "Data de nascimento", "Idade (d)", "Idade (m)", "Peso (kg)", "Edema", "Deitado",
                               "Estatura (cm)", "z P/I", "z E/I", "z IMC/I", "Flag", "Fator de peso",
                               "Nascimento estimado"]

/// Cenários das colunas de dados adicionais (`GetDataStructure`, change add-additional-data).
@Suite("additional-data: colunas")
struct AdditionalDataColumnsScenarioTests {
    // Scenario: Colunas do modelo padrão
    @Test func defaultTemplateAddsSevenColumns() throws {
        let definition = try AdditionalDataXML.decode(try iaTemplateFixture())
        let columns = AdditionalDataColumns.structure(of: definition, forbiddenKeys: fixedSurveyColumnTitles)
        #expect(columns.map(\.key) == ["Menarche/spermarche", "Self-reported", "Sport", "TV/computer",
                                       "Fruit&veg portions / day", "Blood pressure", "Blood lipids"])
        #expect(columns.map(\.sectionID) == ["Maturation", "Maturation", "Physical activity", "Physical activity",
                                             "Food", "Health", "Health"])
        #expect(fixedSurveyColumnTitles.count + columns.count == 26)
    }

    // Scenario: Chaves repetidas
    @Test func duplicateAndForbiddenKeysGetNumericSuffix() {
        let definition = AdditionalData(sections: [
            AdditionalDataSection(identifier: "A", variables: [AdditionalDataVariable(identifier: "x", kind: .text(nil))]),
            AdditionalDataSection(identifier: "B", variables: [AdditionalDataVariable(identifier: "x", kind: .text(nil))]),
            AdditionalDataSection(identifier: "C", variables: [AdditionalDataVariable(identifier: "Sexo", kind: .text(nil))]),
        ])
        let columns = AdditionalDataColumns.structure(of: definition, forbiddenKeys: fixedSurveyColumnTitles)
        #expect(columns.map(\.key) == ["x", "x 2", "Sexo 2"])
        #expect(columns.map(\.sectionID) == ["A", "B", "C"])
        #expect(columns.map(\.variableID) == ["x", "x", "Sexo"])
    }
}
