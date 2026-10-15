import AnthroAnalysis
import AnthroCore
import AnthroIO
import Foundation
import Observation

public enum SeriesColor: Sendable, Equatable {
    case green, red, violet, blue
}

/// Uma curva do gráfico de densidade, com rótulo e cor.
public struct DensitySeries: Sendable, Equatable {
    public let label: String
    public let color: SeriesColor
    public let curve: DensityCurve

    public init(label: String, color: SeriesColor, curve: DensityCurve) {
        self.label = label
        self.color = color
        self.curve = curve
    }
}

/// Aba de resultados e relatórios do inquérito aberto (`tabNutriSurvey_Selected`, `tsComboFilter_SelectedIndexChanged`,
/// `tsbExportExcel_Click`, `tsbReportExcelGlobal_Click`).
@MainActor
@Observable
public final class SurveyAnalysisModel {
    public enum GraphFilter: CaseIterable, Sendable {
        case allChildren, bySex, byCluster, byAgeGroup
    }

    public enum Graph: Equatable {
        case empty(title: String)
        case density([DensitySeries])
        case bars([MeanSDBar], axisLabel: String)
    }

    /// `tabNutriSurvey_Selected`: o mínimo conta todos os registros, válidos ou não (D13).
    static let minimumRecords = 12
    private static let densityX: ClosedRange<Double> = -5...5
    private static let densityY: ClosedRange<Double> = 0...0.45

    public var indicator: Indicator = .weightForAge
    public var filter: GraphFilter = .allChildren
    public private(set) var graph: Graph = .empty(title: "")
    public private(set) var xDomain: ClosedRange<Double> = 0...0
    public private(set) var yDomain: ClosedRange<Double> = 0...0
    public private(set) var errorMessage: String?
    public private(set) var lastReport: SurveyReport?

    @ObservationIgnored private var records: [AnalysisRecord]
    @ObservationIgnored private var recordCount: Int
    @ObservationIgnored private let options: SurveyOptions
    @ObservationIgnored private let surveyName: String
    /// Vista inicial do gráfico, restaurada por `resetZoom`.
    @ObservationIgnored private var initialDomains: (x: ClosedRange<Double>, y: ClosedRange<Double>) = (0...0, 0...0)
    /// `InitSurface`: a normal com resolução 500, calculada uma vez.
    @ObservationIgnored private lazy var normal = DensitySeries(label: L10n.SurveyAnalysis.normalCurve, color: .green,
                                                                curve: DensityEstimation.normalCurve(resolution: 500))

    public init(records: [AnalysisRecord], options: SurveyOptions, surveyName: String, recordCount: Int) {
        self.records = records
        self.options = options
        self.surveyName = surveyName
        self.recordCount = recordCount
    }

    /// Registros gravados do inquérito, depois de salvar.
    public func update(records: [AnalysisRecord], recordCount: Int) {
        self.records = records
        self.recordCount = recordCount
    }

    public var canShowGraphs: Bool {
        recordCount >= Self.minimumRecords
    }

    public var unavailableMessage: String? {
        canShowGraphs ? nil : L10n.SurveyAnalysis.recordsRequired
    }

    /// `tsComboFilter_SelectedIndexChanged`: densidade de todas as crianças ou por sexo, ou barras por cluster ou por faixa;
    /// sem dados, ou com largura zero em qualquer série, o gráfico fica vazio com "(Sem dados)" (D13).
    public func refreshGraph() {
        guard canShowGraphs else {
            show(.empty(title: ""), x: 0...0, y: 0...0)
            return
        }
        switch filter {
        case .allChildren:
            let selection = DensityEstimation.zScores(records, indicator: indicator)
            guard !selection.zScores.isEmpty,
                  let curve = try? DensityEstimation.epanechnikov(zScores: selection.zScores, weights: selection.weights) else {
                return showNoData()
            }
            showDensity([normal, series(L10n.SurveyAnalysis.allChildren, .red, curve)])
        case .bySex:
            var series: [DensitySeries] = [normal]
            for (sex, label, color) in [(Sex.girl, L10n.SurveyAnalysis.female, SeriesColor.violet),
                                        (Sex.boy, L10n.SurveyAnalysis.male, SeriesColor.blue)] {
                let population = PrevalenceCalculator.filtered(records, sex: sex, onlyWithCluster: false)
                let selection = DensityEstimation.zScores(population, indicator: indicator)
                guard !selection.zScores.isEmpty else { continue }
                guard let curve = try? DensityEstimation.epanechnikov(zScores: selection.zScores, weights: selection.weights) else {
                    return showNoData()
                }
                series.append(self.series(label, color, curve))
            }
            guard series.count > 1 else { return showNoData() }
            showDensity(series)
        case .byCluster:
            showBars(MeanSDBars.byCluster(records, indicator: indicator, options: options), axis: L10n.SurveyAnalysis.cluster)
        case .byAgeGroup:
            showBars(MeanSDBars.byAgeGroup(records, indicator: indicator, options: options), axis: L10n.SurveyAnalysis.ageMonths)
        }
    }

    /// Zoom por retângulo de seleção; retângulo sem largura ou altura, ou gráfico vazio, não muda a vista.
    public func zoom(x: ClosedRange<Double>, y: ClosedRange<Double>) {
        guard canCopyGraph, x.upperBound > x.lowerBound, y.upperBound > y.lowerBound else { return }
        xDomain = x
        yDomain = y
    }

    public func resetZoom() {
        xDomain = initialDomains.x
        yDomain = initialDomains.y
    }

    public var canCopyGraph: Bool {
        if case .empty = graph { return false }
        return true
    }

    /// Gera o relatório, grava e abre na planilha; `AnalysisError.noClusterData` e falhas de gravação viram as mensagens
    /// do original, sem arquivo.
    public func exportReport(_ kind: SurveyReportKind, to url: URL, opener: ReportOpening) {
        errorMessage = nil
        let report: SurveyReport
        do {
            switch kind {
            case .standard(let improved):
                report = try SurveyReportWriter.standardReport(records: records, options: options, improvedClusterAnalysis: improved)
            case .estimates:
                report = try SurveyReportWriter.estimatesReport(records: records, options: options)
            }
        } catch AnalysisError.noClusterData {
            errorMessage = L10n.SurveyAnalysis.missingCluster
            return
        } catch {
            errorMessage = "\(error)"
            return
        }
        lastReport = report
        do {
            try SurveyReportWriter.write(report, to: url)
        } catch {
            errorMessage = L10n.SurveyAnalysis.fileError
            return
        }
        ReportLauncher.open(url, using: opener)
    }

    /// Nome padrão do arquivo do relatório, com "Relatório" para inquérito sem nome.
    public func defaultFileName(_ kind: SurveyReportKind) -> String {
        SurveyReportWriter.defaultFileName(surveyName: surveyName, kind: kind)
    }

    // MARK: Privado

    /// Rótulo com o tamanho ponderado arredondado, como `AnthroComputation.Round(sampleSize, 0)`.
    private func series(_ label: String, _ color: SeriesColor, _ curve: DensityCurve) -> DensitySeries {
        let size = ClinicalRounding.round(curve.sampleSize, places: 0) ?? curve.sampleSize
        return DensitySeries(label: "\(label) (n=\(size))", color: color, curve: curve)
    }

    private func showNoData() {
        show(.empty(title: L10n.SurveyAnalysis.noData), x: Self.densityX, y: Self.densityY)
    }

    private func showDensity(_ series: [DensitySeries]) {
        show(.density(series), x: Self.densityX, y: Self.densityY)
    }

    /// Barras com soma de contagens menor que 1 não têm dados; o eixo x vai de uma posição antes da primeira a duas depois
    /// da última, como os `WorldMin` e `WorldMax` do original.
    private func showBars(_ bars: [MeanSDBar], axis: String) {
        guard bars.reduce(0, { $0 + $1.count }) >= 1, let first = bars.first, let last = bars.last else { return showNoData() }
        let ends: [Double] = bars.flatMap { bar -> [Double] in [bar.mean, bar.whiskerEnd].compactMap { $0 } } + [0]
        let low = (ends.min() ?? 0) - 0.5
        let high = (ends.max() ?? 0) + 0.5
        show(.bars(bars, axisLabel: axis), x: Double(first.position - 1)...Double(last.position + 2), y: low...high)
    }

    private func show(_ graph: Graph, x: ClosedRange<Double>, y: ClosedRange<Double>) {
        self.graph = graph
        initialDomains = (x, y)
        xDomain = x
        yDomain = y
    }
}
