import AnthroFeatures
import Testing

@Suite("additional-data: rótulos (unitários)")
struct AdditionalDataLabelsUnitTests {
    @Test(arguments: [
        ("Maturation", "Maturação"),
        ("Menarche/spermarche", "Menarca/espermarca"),
        ("Self-reported", "Autorreferido"),
        ("Physical activity", "Atividade física"),
        ("Sport", "Esporte"),
        ("TV/computer", "TV/computador"),
        ("Food", "Alimentação"),
        ("Fruit&veg portions / day", "Porções de frutas e hortaliças por dia"),
        ("Health", "Saúde"),
        ("Blood pressure", "Pressão arterial"),
        ("Blood lipids", "Lipídios sanguíneos"),
    ])
    func defaultIdentifierIsTranslated(identifier: String, label: String) {
        #expect(AdditionalDataLabels.display(identifier) == label)
    }

    @Test func defaultDescriptionIsTranslatedAndOthersPassThrough() {
        #expect(AdditionalDataLabels.displayDescription("hours per week") == "horas por semana")
        #expect(AdditionalDataLabels.displayDescription("minutos") == "minutos")
        #expect(AdditionalDataLabels.displayDescription(nil) == nil)
        #expect(AdditionalDataLabels.display("sport") == "sport")
        #expect(AdditionalDataLabels.display("") == "")
    }
}
