import AnthroAnalysis
import AnthroCore
import Foundation

/// `NSMain.CreateExcelReport`, `GetReportForIndicator` e `GetWHOReport` (design D8 a D11): as linhas literais do
/// original, com os rótulos em pt-BR.
public enum SurveyReportWriter {
    private typealias S = ReportStrings

    /// `_AGESLICEDTOTALGROUPS`: as faixas fixas de 5 a 9, 10 a 14 e 15 a 19 anos.
    static let slicedBoundaries = [61, 120, 180, 228]
    private static let indicators: [Indicator] = [.weightForAge, .lengthOrHeightForAge, .bmiForAge]

    /// Relatório padrão: conjuntos 1 a 3 por sexo, o Conjunto 4 por cluster só sem correção, e as notas.
    public static func standardReport(records: [AnalysisRecord], options: SurveyOptions,
                                      improvedClusterAnalysis: Bool) throws -> SurveyReport {
        var lines = [S.standardTitle, S.ciTables + "*", ""]
        for (title, sex) in [(S.set1, nil), (S.set2, Sex.boy), (S.set3, Sex.girl)] as [(String, Sex?)] {
            lines += [title, ""]
            for indicator in indicators {
                lines.append(header(S.ageGroups, indicator))
                lines.append(columns(indicator, withAges: true))
                lines += try indicatorRows(records, indicator: indicator, options: options, sex: sex, byCluster: false,
                                           improved: improvedClusterAnalysis)
                lines.append("")
            }
        }
        if !improvedClusterAnalysis {
            lines += [S.set4, ""]
            for indicator in indicators {
                lines.append(header(S.cluster, indicator))
                lines.append(columns(indicator, withAges: false))
                lines += try indicatorRows(records, indicator: indicator, options: options, sex: nil, byCluster: true, improved: false)
                lines.append("")
            }
        }
        lines += notes(records)
        if improvedClusterAnalysis {
            lines += ["", "-) " + S.extremePrevalencesNote, ".) " + S.singleClusterNote]
        }
        return SurveyReport(kind: .standard(improvedClusterAnalysis: improvedClusterAnalysis), lines: lines)
    }

    /// Relatório de estimativas do banco global da OMS: metadados, conjuntos 1 a 4 sem IC e as notas sem as de cluster.
    public static func estimatesReport(records: [AnalysisRecord], options: SurveyOptions) throws -> SurveyReport {
        var lines = [S.globalTitle + "*", "", S.country + ":", S.reference + ":", S.adminLevel + ":", S.surveyMonthYear + ":", ""]
        for (title, sex, byCluster) in [(S.set1, nil, false), (S.set2, Sex.boy, false), (S.set3, Sex.girl, false),
                                        (S.set4, nil, true)] as [(String, Sex?, Bool)] {
            lines.append(title)
            lines += try estimateRows(records, options: options, sex: sex, byCluster: byCluster)
            lines.append("")
        }
        lines += notes(records)
        return SurveyReport(kind: .estimates, lines: lines)
    }

    /// Nomes de `tsbExportExcel_Click` e `tsbReportExcelGlobal_Click`, com "Relatório" para inquérito sem nome.
    public static func defaultFileName(surveyName: String, kind: SurveyReportKind) -> String {
        let trimmed = surveyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? S.defaultFileName : trimmed
        switch kind {
        case .standard(improvedClusterAnalysis: false): return "\(name)_standard.txt"
        case .standard(improvedClusterAnalysis: true): return "\(name)_standard_cluster.txt"
        case .estimates: return "\(name)_estimates.txt"
        }
    }

    /// UTF-16 little-endian com BOM e CRLF, como o `StreamWriter` com `Encoding.Unicode` (D10).
    public static func write(_ report: SurveyReport, to url: URL) throws {
        var data = Data([0xFF, 0xFE])
        data.append(report.text.data(using: .utf16LittleEndian) ?? Data())
        try data.write(to: url, options: .atomic)
    }

    // MARK: Relatório padrão

    private static func label(_ indicator: Indicator) -> String {
        switch indicator {
        case .weightForAge: S.weightForAge + "**"
        case .lengthOrHeightForAge: S.lengthOrHeightForAge
        case .bmiForAge: S.bmiForAge
        }
    }

    private static func header(_ first: String, _ indicator: Indicator) -> String {
        "\(first)\t\t\(S.count)\t\(label(indicator)) (%)"
    }

    private static func columns(_ indicator: Indicator, withAges: Bool) -> String {
        let ages = withAges ? "\(S.years)\t\(S.months)" : "\t"
        var fields = ["% < -3\(S.sd)", S.ci, "% < -2\(S.sd)", S.ci]
        if !PrevalenceCalculator.computeOnlyNegative(indicator) {
            fields += ["% > +1\(S.sd)", S.ci, "% > +2\(S.sd)", S.ci, "% > +3\(S.sd)", S.ci]
        }
        return ([ages, ""] + fields + [S.mean, S.sd]).joined(separator: "\t")
    }

    /// `GetReportForIndicator`: total, faixas fixas e faixas do inquérito, ou total e clusters.
    private static func indicatorRows(_ records: [AnalysisRecord], indicator: Indicator, options: SurveyOptions, sex: Sex?,
                                      byCluster: Bool, improved: Bool) throws -> [String] {
        var rows: [String] = []
        let population = byCluster
            ? PrevalenceCalculator.filtered(records, sex: nil, onlyWithCluster: true)
            : PrevalenceCalculator.filtered(records, sex: sex, onlyWithCluster: improved)
        let total = try PrevalenceCalculator.compute(population, indicator: indicator, options: options, analysisType: .standard,
                                                     isTotal: true, byCluster: byCluster, improvedClusterAnalysis: improved)
        let boundaries = options.ageGroupBoundaries
        if !byCluster {
            if total.count == 0 {
                rows.append("\(S.total)\t\t\(count(total))")
            } else {
                let start = boundaries[indexOf61(boundaries)]
                let last = boundaries.last ?? 0
                let labels = ["\(S.total) (\(start / 12)-\(last / 12))", "(\(start)-\(last))"]
                if indicator == .weightForAge {
                    rows.append((labels + Array(repeating: "", count: 7)).joined(separator: "\t"))
                } else {
                    rows.append((labels + values(total, indicator)).joined(separator: "\t"))
                }
            }
        } else if total.count != 0 {
            rows.append(([S.total, ""] + values(total, indicator)).joined(separator: "\t"))
        }
        if byCluster {
            for cluster in PrevalenceCalculator.byCluster(records, indicator: indicator, options: options, analysisType: .standard)
            where cluster.result.count != 0 {
                rows.append((["\(cluster.cluster)", ""] + values(cluster.result, indicator)).joined(separator: "\t"))
            }
            return rows
        }
        var sliced = options
        sliced.ageGroupBoundaries = slicedBoundaries
        let slicedResults = try PrevalenceCalculator.byAgeGroups(records, indicator: indicator, options: sliced, analysisType: .standard,
                                                                 sex: sex, improvedClusterAnalysis: improved)
        for (index, result) in slicedResults.enumerated() {
            let (start, end) = bounds(slicedBoundaries, index)
            rows.append(groupRow("\(S.total) (\(start / 12)-\(end / 12))", start: start, end: end, result: result, indicator: indicator))
        }
        let groups = try PrevalenceCalculator.byAgeGroups(records, indicator: indicator, options: options, analysisType: .standard,
                                                          sex: sex, improvedClusterAnalysis: improved)
        for (index, result) in groups.enumerated() {
            let (start, end) = bounds(boundaries, index)
            rows.append(groupRow("\(start / 12)", start: start, end: end, result: result, indicator: indicator))
        }
        return rows
    }

    /// Faixa vazia, ou de peso para idade começando abaixo de 11 ou acima de 108 meses, sai só com rótulo e intervalo.
    private static func groupRow(_ label: String, start: Int, end: Int, result: PrevalenceResult, indicator: Indicator) -> String {
        let labels = [label, "(\(start)-\(end))"]
        if result.count == 0 || (indicator == .weightForAge && (start < 11 || start > 108)) {
            return (labels + [""]).joined(separator: "\t")
        }
        return (labels + values(result, indicator)).joined(separator: "\t")
    }

    /// N, prevalências com IC e média e DP com 2 casas.
    private static func values(_ result: PrevalenceResult, _ indicator: Indicator) -> [String] {
        let thresholds: [Threshold] = PrevalenceCalculator.computeOnlyNegative(indicator)
            ? [.belowMinus3, .belowMinus2] : Threshold.allCases
        return [count(result)] + thresholds.flatMap { [ReportFormat.number(result.prevalence($0)), ReportFormat.interval(result.interval($0))] }
            + [ReportFormat.number(round2(result.mean)), ReportFormat.number(round2(result.standardDeviation))]
    }

    // MARK: Relatório de estimativas

    /// `GetWHOReport`: duas linhas de cabeçalho e uma linha de 18 colunas, mais tabulação final, por total e faixa ou
    /// cluster; N é o de estatura para idade.
    private static func estimateRows(_ records: [AnalysisRecord], options: SurveyOptions, sex: Sex?, byCluster: Bool) throws -> [String] {
        var sliced = options
        sliced.ageGroupBoundaries = slicedBoundaries
        var results: [[PrevalenceResult]] = []
        var clusters: [Int] = []
        for indicator in indicators {
            if byCluster {
                let population = PrevalenceCalculator.filtered(records, sex: nil, onlyWithCluster: true)
                let byCluster = PrevalenceCalculator.byCluster(records, indicator: indicator, options: options, analysisType: .whoGlobalDatabase)
                clusters = byCluster.map(\.cluster)
                results.append([try PrevalenceCalculator.compute(population, indicator: indicator, options: options,
                                                                 analysisType: .whoGlobalDatabase, isTotal: true, byCluster: true,
                                                                 improvedClusterAnalysis: false)] + byCluster.map(\.result))
            } else {
                let population = PrevalenceCalculator.filtered(records, sex: sex, onlyWithCluster: false)
                results.append([try PrevalenceCalculator.compute(population, indicator: indicator, options: options,
                                                                 analysisType: .whoGlobalDatabase, isTotal: true, byCluster: false,
                                                                 improvedClusterAnalysis: false)]
                    + (try PrevalenceCalculator.byAgeGroups(records, indicator: indicator, options: sliced, analysisType: .whoGlobalDatabase,
                                                            sex: sex, improvedClusterAnalysis: false))
                    + (try PrevalenceCalculator.byAgeGroups(records, indicator: indicator, options: options, analysisType: .whoGlobalDatabase,
                                                            sex: sex, improvedClusterAnalysis: false)))
            }
        }
        let sd = S.sd
        var rows = [
            "\(byCluster ? S.cluster : S.ageGroups)\t\t\(S.count)\t\(S.weightForAge)** (%)\t\t\t\t\(S.lengthOrHeightForAge) (%)\t\t\t\t\(S.bmiForAge)",
            "\(byCluster ? "" : S.years)\t\(byCluster ? "" : S.months)\t\t% < -3\(sd)\t% < -2\(sd)\t\(S.mean)\t\(sd)\t% < -3\(sd)\t% < -2\(sd)\t\(S.mean)\t\(sd)\t% < -3\(sd)\t% < -2\(sd)\t% > +1\(sd)\t% > +2\(sd)\t% > +3\(sd)\t\(S.mean)\t\(sd)\t",
        ]
        if byCluster && results[0].count < 2 { return rows }
        let boundaries = options.ageGroupBoundaries
        var label = S.total
        var range = ""
        if !byCluster {
            let start = boundaries[indexOf61(boundaries)]
            let last = boundaries.last ?? 0
            label = "\(S.total) (\(start / 12)-\(last / 12))"
            range = "(\(start)-\(last))"
        }
        let heightTotal = results[1][0]
        if ClinicalRounding.round(heightTotal.count + heightTotal.oedemaCount, places: 2) == 0 {
            rows.append(emptyEstimate(label, range))
        } else {
            rows.append(estimate(label, range, results, at: 0, weightBlank: !byCluster))
        }
        let slicedCount = slicedBoundaries.count - 1
        for index in 1..<results[0].count {
            if byCluster {
                label = "\(clusters[index - 1])"
            } else if index < 1 + slicedCount {
                let (start, end) = bounds(slicedBoundaries, index - 1)
                label = "\(S.total) (\(start / 12)-\(end / 12))"
                range = "(\(start)-\(end))"
            } else {
                let (start, end) = bounds(boundaries, index - 1 - slicedCount)
                label = "\(start / 12)"
                range = "(\(start)-\(end))"
            }
            let height = results[1][index]
            let weight = results[0][index]
            if height.count + height.oedemaCount == 0 {
                rows.append(emptyEstimate(label, range))
            } else {
                // Peso com < -3, < -2, média e DP iguais a 0 é peso sem dados (acima de 108 meses).
                let weightBlank = weight.prevalence(.belowMinus3) == 0 && weight.prevalence(.belowMinus2) == 0
                    && round2(weight.mean) == 0 && round2(weight.standardDeviation) == 0
                rows.append(estimate(label, range, results, at: index, weightBlank: weightBlank))
            }
        }
        return rows
    }

    private static func estimate(_ label: String, _ range: String, _ results: [[PrevalenceResult]], at index: Int,
                                 weightBlank: Bool) -> String {
        let weight = results[0][index]
        let height = results[1][index]
        let bmi = results[2][index]
        let n = ClinicalRounding.round(height.count + height.oedemaCount, places: 0)
        let weightFields = weightBlank ? ["", "", "", ""] : estimateValues(weight, [.belowMinus3, .belowMinus2])
        let fields = [label, range, ReportFormat.number(n)] + weightFields + estimateValues(height, [.belowMinus3, .belowMinus2])
            + estimateValues(bmi, Threshold.allCases)
        return fields.joined(separator: "\t") + "\t"
    }

    private static func estimateValues(_ result: PrevalenceResult, _ thresholds: [Threshold]) -> [String] {
        thresholds.map { ReportFormat.number(result.prevalence($0)) }
            + [ReportFormat.number(round2(result.mean)), ReportFormat.number(round2(result.standardDeviation))]
    }

    /// N igual a 0: só rótulos e "0", com as 15 colunas vazias e a tabulação final.
    private static func emptyEstimate(_ label: String, _ range: String) -> String {
        ([label, range, "0"] + Array(repeating: "", count: 15)).joined(separator: "\t") + "\t"
    }

    // MARK: Comuns

    /// Notas finais; a contagem de edema usa todos os registros do inquérito (`GetChildrenWithOedemaCount`).
    private static func notes(_ records: [AnalysisRecord]) -> [String] {
        ["*) " + S.valuesBasedOnStandards, S.noteValidZ, S.noteOedema, S.noteSD,
         S.oedemaCases(records.filter { $0.hasOedema == true }.count), "", "**) " + S.noteWeightForAge]
    }

    /// Índice do último limite igual a 61; sem ele, 0, como o laço do original.
    private static func indexOf61(_ boundaries: [Int]) -> Int {
        boundaries.lastIndex(of: 61) ?? 0
    }

    /// Início e fim da faixa `index`: o fim é o limite seguinte menos 1, exceto na última faixa.
    private static func bounds(_ boundaries: [Int], _ index: Int) -> (start: Int, end: Int) {
        let end = index == boundaries.count - 2 ? boundaries[index + 1] : boundaries[index + 1] - 1
        return (boundaries[index], end)
    }

    private static func count(_ result: PrevalenceResult) -> String {
        ReportFormat.number(ClinicalRounding.round(result.count + result.oedemaCount, places: 0))
    }

    private static func round2(_ value: Decimal?) -> Decimal? {
        ClinicalRounding.round(value, places: 2)
    }
}
