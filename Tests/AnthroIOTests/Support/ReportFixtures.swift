import AnthroAnalysis
import AnthroCore
import AnthroIO
import Foundation

/// Inquéritos dos cenários de relatório (`tenChildren`, `fourClusters`) e localização de tabelas no texto.
enum ReportFixtures {
    static let tenZ = ["-3.5", "-2.5", "-2.1", "-1.0", "0.0", "0.5", "1.2", "2.2", "3.1", "0.0"].map(d)

    static let weightHeader = "Faixas etárias\t\tN\tPeso para idade** (%)"
    static let heightHeader = "Faixas etárias\t\tN\tComprimento/estatura para idade (%)"
    static let bmiHeader = "Faixas etárias\t\tN\tIMC para idade (%)"
    static let set1 = "Conjunto 1: Sexos combinados"
    static let set2 = "Conjunto 2: Masculino"
    static let set3 = "Conjunto 3: Feminino"
    static let set4 = "Conjunto 4: Geral, sexos combinados por cluster"

    /// Registro com o mesmo z nos três indicadores.
    static func record(age: Decimal? = 96, z: Decimal?, sex: Sex? = .boy, cluster: Int? = nil, oedema: Bool? = nil,
                       indicators: [Indicator] = Indicator.allCases) -> AnalysisRecord {
        var scores: [Indicator: Decimal] = [:]
        if let z { for indicator in indicators { scores[indicator] = z } }
        return AnalysisRecord(ageInMonths: age, sex: sex, cluster: cluster, hasOedema: oedema, zScores: scores)
    }

    /// Dez registros de 96 meses (5 meninos e 5 meninas), fator 1, sem edema e sem cluster.
    static func tenChildren() -> [AnalysisRecord] {
        tenZ.enumerated().map { record(z: $0.element, sex: $0.offset < 5 ? .boy : .girl) }
    }

    /// Vinte registros de 96 meses, 5 por cluster (1 a 4), com 1, 2, 0 e 1 registros de z -2.5 e os demais com z 0.
    static func fourClusters() -> [AnalysisRecord] {
        let cases = [1: 1, 2: 2, 3: 0, 4: 1]
        return (1...4).flatMap { cluster in
            (0..<5).map { index in record(z: index < cases[cluster]! ? d("-2.5") : 0, sex: index.isMultiple(of: 2) ? .boy : .girl,
                                          cluster: cluster) }
        }
    }

    /// Linhas do conjunto `set`: do título do conjunto ao próximo conjunto ou às notas.
    static func set(_ report: SurveyReport, _ title: String) -> [String]? {
        guard let start = report.lines.firstIndex(of: title) else { return nil }
        let rest = report.lines[(start + 1)...]
        let end = rest.firstIndex { $0.hasPrefix("Conjunto ") || $0.hasPrefix("*) ") } ?? report.lines.endIndex
        return Array(report.lines[(start + 1)..<end])
    }

    /// Linhas de dados da tabela que abre com `header` no conjunto `title`: depois das duas linhas de cabeçalho, até a
    /// linha vazia.
    static func table(_ report: SurveyReport, set title: String, header: String) -> [String]? {
        guard let lines = set(report, title), let start = lines.firstIndex(of: header), start + 2 <= lines.count else { return nil }
        let rows = lines[(start + 2)...]
        return Array(rows.prefix { !$0.isEmpty })
    }
}
