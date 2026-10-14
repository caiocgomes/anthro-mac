import AnthroCore
import Foundation
import Testing

/// Testes de cenário da capability growth-reference-data (change port-anthro-engine).
@Suite("growth-reference-data")
struct GrowthReferenceDataTests {
    let tables: GrowthReferenceTables

    init() throws {
        tables = try GrowthReferenceTables.bundled()
    }

    // Scenario: Linha do dia 0 de peso para idade de meninos
    @Test func linhaDoDia0DePesoParaIdadeDeMeninos() {
        #expect(tables.standardsLMS(.weightForAge, sex: .boy, ageInDays: 0) == LMS(l: d("0.3487"), m: d("3.3464"), s: d("0.14602")))
    }

    // Scenario: Último dia dos padrões de IMC de meninas
    @Test func ultimoDiaDosPadroesDeImcDeMeninas() {
        #expect(tables.standardsLMS(.bmiForAge, sex: .girl, ageInDays: 1856) == LMS(l: d("-0.5684"), m: d("15.2798"), s: d("0.09825")))
    }

    // Scenario: Dia além do fim dos padrões
    @Test func diaAlemDoFimDosPadroes() {
        #expect(tables.standardsLMS(.weightForAge, sex: .boy, ageInDays: 1857) == nil)
    }

    // Scenario: Mês 61 de IMC para idade de meninos
    @Test func mes61DeImcParaIdadeDeMeninos() {
        #expect(tables.referenceLMS(.bmiForAge, sex: .boy, ageInMonths: 61) == LMS(l: d("-0.7387"), m: d("15.2641"), s: d("0.08390")))
    }

    // Scenario: Peso para idade além de 121 meses
    @Test func pesoParaIdadeAlemDe121Meses() {
        #expect(tables.referenceLMS(.weightForAge, sex: .boy, ageInMonths: 122) == nil)
    }

    // Scenario: IMC de meninos aos 61,5 meses
    @Test func imcDeMeninosAos61eMeioMeses() {
        #expect(tables.referenceLMS(.bmiForAge, sex: .boy, ageInMonths: d("61.5")) == LMS(l: d("-0.7504"), m: d("15.26285"), s: d("0.08402")))
    }

    // Scenario: Último intervalo válido de estatura
    @Test func ultimoIntervaloValidoDeEstatura() {
        #expect(tables.referenceLMS(.lengthOrHeightForAge, sex: .girl, ageInMonths: d("228.5")) == LMS(l: 1, m: d("163.1548"), s: d("0.04009")))
    }

    // Scenario: Mês superior ausente
    @Test func mesSuperiorAusente() {
        #expect(tables.referenceLMS(.bmiForAge, sex: .boy, ageInMonths: d("229.5")) == nil)
    }

    // Scenario: Mês inferior ausente
    @Test func mesInferiorAusente() {
        #expect(tables.referenceLMS(.bmiForAge, sex: .boy, ageInMonths: d("59.5")) == nil)
    }

    // Scenario: Recurso embutido completo
    @Test func recursoEmbutidoCompleto() {
        for indicator in Indicator.allCases {
            for sex in Sex.allCases {
                #expect(tables.rowCount(indicator, range: .standards, sex: sex) == 1857, "\(indicator) \(sex)")
                #expect(tables.rowCount(indicator, range: .reference, sex: sex) == (indicator == .weightForAge ? 62 : 170), "\(indicator) \(sex)")
            }
        }
    }

    // Scenario: Recurso com dia faltando
    @Test func recursoComDiaFaltando() {
        func csv(_ ages: ClosedRange<Int>, missingBoyAge: Int? = nil) -> String {
            var lines = ["sex,age,l,m,s"]
            for sex in [1, 2] {
                for age in ages where !(sex == 1 && age == missingBoyAge) {
                    lines.append("\(sex),\(age),1,10,0.1")
                }
            }
            return lines.joined(separator: "\n")
        }
        let standards: [Indicator: String] = [
            .weightForAge: csv(0...1856, missingBoyAge: 100),
            .lengthOrHeightForAge: csv(0...1856),
            .bmiForAge: csv(0...1856),
        ]
        let reference: [Indicator: String] = [
            .weightForAge: csv(60...121),
            .lengthOrHeightForAge: csv(60...229),
            .bmiForAge: csv(60...229),
        ]
        #expect(throws: ReferenceDataError.gap(indicator: .weightForAge, sex: .boy, age: 100)) {
            try GrowthReferenceTables.load(standardsCSV: standards, referenceCSV: reference)
        }
    }

    // Scenario: Linha +2 DP no dia 0 de peso de meninos
    @Test func linhaMais2DpNoDia0DePesoDeMeninos() throws {
        #expect(GrowthCurves.zScoreOffsets == [-3, -2, -1, 0, 1, 2, 3])
        let points = GrowthCurves.points(.weightForAge, sex: .boy, kind: .zScore, tables: tables)
        let first = try #require(points.first)
        #expect(first.xMonths == 0)
        try #require(first.values.count == 7)
        #expect(round4(first.values[3]) == 3.3464)
        #expect(round4(first.values[5]) == 4.4194)
    }

    // Scenario: Número de pontos e limite superior de peso
    @Test func numeroDePontosELimiteSuperiorDePeso() {
        let points = GrowthCurves.points(.weightForAge, sex: .girl, kind: .zScore, tables: tables)
        #expect(points.count == 526)
        #expect(points.last?.xMonths == 120)
    }

    // Scenario: Percentil 50 igual à mediana
    @Test func percentil50IgualAMediana() throws {
        #expect(GrowthCurves.percentileOffsets == [d("-1.88"), d("-1.036"), 0, d("1.036"), d("1.88")])
        let points = GrowthCurves.points(.bmiForAge, sex: .boy, kind: .percentile, tables: tables)
        try #require(points.count == 634)
        for (index, point) in points.enumerated() {
            let source = index < 465
                ? tables.standardsLMS(.bmiForAge, sex: .boy, ageInDays: index * 4)
                : tables.referenceLMS(.bmiForAge, sex: .boy, ageInMonths: Decimal(60 + index - 465))
            let median = try #require(source).m
            #expect(point.values[2] == NSDecimalNumber(decimal: median).doubleValue, "ponto \(index)")
        }
    }

    // Scenario: Limite superior das curvas de IMC
    @Test func limiteSuperiorDasCurvasDeImc() {
        let points = GrowthCurves.points(.bmiForAge, sex: .girl, kind: .percentile, tables: tables)
        #expect(points.count == 634)
        #expect(points.last?.xMonths == 228)
    }
}
