import AnthroAnalysis
import AnthroCore
import AnthroFeatures
import Foundation

/// Porta de abertura de teste: registra as chamadas em vez de abrir apps (dependência externa: NSWorkspace).
final class RecordingReportOpener: ReportOpening {
    var installed: [String: URL] = [:]
    private(set) var opened: [(file: URL, application: URL?)] = []

    func applicationURL(bundleIdentifier: String) -> URL? {
        installed[bundleIdentifier]
    }

    func open(_ file: URL, withApplicationAt application: URL?) {
        opened.append((file, application))
    }
}

enum AnalysisModelFixtures {
    static let normalLabel = "Padrões de crescimento da OMS (nascimento a 60 meses), referência OMS 2007 (61 meses a 19 anos)"
    static let twelveZ = ["-2", "-1.5", "-1", "-0.5", "0", "0", "0.5", "1", "1.5", "2", "-0.25", "0.25"].map(num)

    static func record(age: Decimal? = 96, z: Decimal?, sex: Sex? = .boy, cluster: Int? = nil, factor: Decimal = 1) -> AnalysisRecord {
        var scores: [Indicator: Decimal] = [:]
        if let z { for indicator in Indicator.allCases { scores[indicator] = z } }
        return AnalysisRecord(ageInMonths: age, sex: sex, cluster: cluster, weightingFactor: factor, zScores: scores)
    }

    static func withoutZ(_ count: Int) -> [AnalysisRecord] {
        (0..<count).map { _ in record(z: nil) }
    }

    /// Vinte registros de 96 meses, 5 por cluster (1 a 4), com 1, 2, 0 e 1 registros de z -2.5 e os demais com z 0.
    static func fourClusters() -> [AnalysisRecord] {
        let cases = [1: 1, 2: 2, 3: 0, 4: 1]
        return (1...4).flatMap { cluster in
            (0..<5).map { index in record(z: index < cases[cluster]! ? num("-2.5") : 0, cluster: cluster) }
        }
    }

    static func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("anthro-analysis-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
