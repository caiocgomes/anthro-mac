import AnthroCore
import AnthroIO
import Foundation
import Observation

public enum SurveyExportFormat: CaseIterable, Sendable {
    case xml, tabText, semicolonCSV
}

public enum SurveyExportWarning: Equatable, Sendable {
    case onlyFirstSurveyExported
}

/// Importação e exportação do Inquérito nutricional (`importFromFileToolStripMenuItem_Click`, `NSImportDialog`,
/// `tsbSurveyExport_Click`).
@MainActor
@Observable
public final class SurveyExchangeModel {
    public enum Phase: Equatable {
        case idle
        case mapping(columns: [String], mapping: [SurveyImportField: String])
        case finished(warning: String?)
        case failed(message: String)
    }

    public private(set) var phase: Phase = .idle
    public var selectedSurveyIDs: [Int64] = []
    public var includeResults: Bool = false

    @ObservationIgnored private let source: any SurveyExchangeSource
    @ObservationIgnored private let sink: any SurveyImportSink
    @ObservationIgnored private let presenter: any SurveyDraftPresenter
    @ObservationIgnored private let engine: AnthroEngine

    public init(source: any SurveyExchangeSource, sink: any SurveyImportSink, presenter: any SurveyDraftPresenter,
                engine: AnthroEngine) {
        self.source = source
        self.sink = sink
        self.presenter = presenter
        self.engine = engine
    }

    public var canExport: Bool { false }

    public func beginImport(from url: URL) {}

    public func setMapping(_ field: SurveyImportField, column: String?) {}

    public func confirmMapping() {}

    public func cancelImport() {}

    public func export(format: SurveyExportFormat, to url: URL) throws -> SurveyExportWarning? { nil }

    public static func message(for failure: ImportFailure, fileName: String) -> String { "" }

    public static func warningMessage(rowErrors: [ImportFieldError], hadFieldWarnings: Bool, fileName: String) -> String? {
        nil
    }
}
