/// Rótulos em pt-BR dos identificadores do modelo padrão; o XML guarda os identificadores originais (design D10).
/// No original o rótulo é o próprio identificador (`CreateAddDataControls`); identificadores da usuária passam como estão.
public enum AdditionalDataLabels {
    private static let identifiers: [String: String] = [
        "Maturation": "Maturação",
        "Menarche/spermarche": "Menarca/espermarca",
        "Self-reported": "Autorreferido",
        "Physical activity": "Atividade física",
        "Sport": "Esporte",
        "TV/computer": "TV/computador",
        "Food": "Alimentação",
        "Fruit&veg portions / day": "Porções de frutas e hortaliças por dia",
        "Health": "Saúde",
        "Blood pressure": "Pressão arterial",
        "Blood lipids": "Lipídios sanguíneos",
    ]

    private static let descriptions: [String: String] = [
        "hours per week": "horas por semana",
    ]

    public static func display(_ identifier: String) -> String {
        identifiers[identifier] ?? identifier
    }

    public static func displayDescription(_ description: String?) -> String? {
        description.map { descriptions[$0] ?? $0 }
    }
}
