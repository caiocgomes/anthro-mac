import AnthroAnalysis
import AnthroCore
import AnthroFeatures
import AnthroIO
import Foundation
import Testing

/// Laço interno da entrada da análise e do modelo da aba de resultados.
@MainActor
@Suite("survey-analysis: entrada e modelo (unitários)")
struct SurveyAnalysisUnitTests {
    private typealias F = AnalysisModelFixtures

    private func surveyRecord(months: Decimal? = nil, visit: String? = nil, birth: String? = nil) -> SurveyRecord {
        var record = SurveyRecord(sex: .girl, weightingFactor: num("1.5"))
        record.ageInMonths = months
        record.visitDate = visit.map(day)
        record.dateOfBirth = birth.map(day)
        record.weight = num("18.4")
        record.lengthOrHeight = 110
        record.cluster = 7
        record.hasOedema = false
        return record
    }

    @Test func inputUsesTheDatesWhenThereIsNoTypedAge() throws {
        let engine = try AnthroEngine.shared()
        let record = surveyRecord(visit: "2021-04-01", birth: "2016-03-15")
        let input = try #require(SurveyAnalysisInput.records(from: [record], options: .default, engine: engine).first)
        #expect(input.ageInMonths == SurveyRecordEvaluation.ageInMonths(record))
        let result = SurveyRecordEvaluation.result(record, engine: engine)
        #expect(input.zScores[.bmiForAge] == result.score(.bmiForAge).zScore)
        #expect(input.cluster == 7)
        #expect(input.weightingFactor == num("1.5"))
        #expect(input.hasOedema == false)
        #expect(input.weight == num("18.4"))
        #expect(input.height == 110)
        #expect(input.sex == .girl)
        #expect(input.flagged.isEmpty)
    }

    @Test func inputPrefersTheTypedAgeAndFlagsMissingScores() throws {
        var record = surveyRecord(months: 96)
        record.weight = nil
        let input = try #require(SurveyAnalysisInput.records(from: [record], options: .default, engine: try AnthroEngine.shared()).first)
        #expect(input.ageInMonths == 96)
        #expect(input.zScores[.weightForAge] == nil)
        #expect(input.flagged.contains(.weightForAge))
        #expect(!input.flagged.contains(.lengthOrHeightForAge))
    }

    @Test func barsFilterShowsAgeGroupsAndClusters() {
        let model = SurveyAnalysisModel(records: F.twelveZ.map { F.record(z: $0, cluster: 2) }, options: .default, surveyName: "a",
                                        recordCount: 12)
        model.indicator = .bmiForAge
        model.filter = .byAgeGroup
        model.refreshGraph()
        guard case .bars(let bars, let axis) = model.graph else {
            Issue.record("expected bars, got \(model.graph)")
            return
        }
        #expect(bars.count == 21)
        #expect(axis == "Idade (meses)")
        #expect(model.canCopyGraph)
        model.filter = .byCluster
        model.refreshGraph()
        guard case .bars(let clusters, let clusterAxis) = model.graph else {
            Issue.record("expected cluster bars, got \(model.graph)")
            return
        }
        #expect(clusters.map(\.label) == ["2"])
        #expect(clusterAxis == "Cluster")
    }

    @Test func exportOpensTheSpreadsheetAndKeepsTheReport() throws {
        let directory = try F.directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = SurveyAnalysisModel(records: F.fourClusters(), options: .default, surveyName: "Escola A", recordCount: 20)
        let opener = RecordingReportOpener()
        opener.installed = [ReportLauncher.numbersBundleID: URL(fileURLWithPath: "/Applications/Numbers.app")]
        let url = directory.appendingPathComponent("r.txt")
        model.exportReport(.estimates, to: url, opener: opener)
        #expect(model.errorMessage == nil)
        #expect(model.lastReport?.kind == .estimates)
        #expect(opener.opened.map(\.file) == [url])
        #expect(opener.opened.first?.application?.lastPathComponent == "Numbers.app")
        #expect(model.defaultFileName(.estimates) == "Escola A_estimates.txt")
    }

    @Test func zoomOnAnEmptyGraphIsIgnoredAndUnavailableSurveyHasNoGraph() {
        let empty = SurveyAnalysisModel(records: F.withoutZ(12), options: .default, surveyName: "a", recordCount: 12)
        empty.refreshGraph()
        let before = (empty.xDomain, empty.yDomain)
        empty.zoom(x: -1...1, y: 0...0.1)
        #expect(empty.xDomain == before.0)
        #expect(empty.yDomain == before.1)
        let small = SurveyAnalysisModel(records: F.twelveZ.map { F.record(z: $0) }, options: .default, surveyName: "a", recordCount: 11)
        small.refreshGraph()
        #expect(small.graph == .empty(title: ""))
        small.update(records: F.twelveZ.map { F.record(z: $0) }, recordCount: 12)
        small.refreshGraph()
        #expect(small.canShowGraphs)
        #expect(small.canCopyGraph)
    }

    /// A análise usa os registros atuais do inquérito aberto, inclusive os ainda não gravados, como o original.
    @Test func openSurveyBuildsTheAnalysisWithItsCurrentRecords() throws {
        let db = try SurveyFixtures.makeDatabase()
        let records = (0..<12).map { index -> SurveyRecord in
            var record = SurveyRecord(sex: index.isMultiple(of: 2) ? .boy : .girl)
            record.ageInMonths = 96
            record.lengthOrHeight = 130
            record.weight = num("26.6")
            record.hasOedema = false
            return record
        }
        let detail = SurveyDetailModel(survey: Survey(name: "Escola A"), records: records, repository: SurveyRepository(database: db),
                                       engine: try AnthroEngine.shared(), today: { day("2026-10-15") })
        let analysis = detail.makeAnalysisModel()
        #expect(analysis.canShowGraphs)
        #expect(analysis.defaultFileName(.estimates) == "Escola A_estimates.txt")
        analysis.indicator = .bmiForAge
        analysis.refreshGraph()
        #expect(analysis.graph != .empty(title: "(Sem dados)"))
    }
}
