import AnthroCore
import AnthroIO
import Foundation
import Observation

public enum SurveyExportFormat: CaseIterable, Sendable {
    case xml, tabText, semicolonCSV

    public var fileExtension: String {
        switch self {
        case .xml: "xml"
        case .tabText: DelimitedFormat.tabText.fileExtension
        case .semicolonCSV: DelimitedFormat.semicolonCSV.fileExtension
        }
    }
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
    /// Tabela e arquivo da importação externa em andamento.
    @ObservationIgnored private var pending: (table: ImportedTable, fileName: String, name: String)?

    public init(source: any SurveyExchangeSource, sink: any SurveyImportSink, presenter: any SurveyDraftPresenter,
                engine: AnthroEngine) {
        self.source = source
        self.sink = sink
        self.presenter = presenter
        self.engine = engine
    }

    /// Os campos da folha de associação, na ordem de `Survey.Field` (o app só enxerga `AnthroFeatures`, design D1).
    public static let importFields = SurveyImportField.allCases

    public var canExport: Bool {
        !selectedSurveyIDs.isEmpty
    }

    /// Escolhe o leitor pela extensão (D2): XML grava tudo numa transação (D12); TXT, CSV, REC e DBF passam pela
    /// associação de colunas com a proposta automática (D9).
    public func beginImport(from url: URL) {
        pending = nil
        let fileName = url.lastPathComponent
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            phase = .failed(message: "\(Self.prefix(fileName)) \(L10n.Exchange.unreadableFile)")
            return
        }
        let kind = SurveyFileKind.forFileExtension(url.pathExtension)
        guard kind != .xml else {
            importXML(data, fileName: fileName)
            return
        }
        do {
            let table = try ExternalTableReader.read(data, kind: kind)
            pending = (table, fileName, url.deletingPathExtension().lastPathComponent)
            phase = .mapping(columns: table.columns, mapping: ColumnAutoMapper.propose(columns: table.columns))
        } catch {
            phase = .failed(message: Self.message(for: error, fileName: fileName))
        }
    }

    public func setMapping(_ field: SurveyImportField, column: String?) {
        guard case .mapping(let columns, var mapping) = phase else { return }
        mapping[field] = column.flatMap { columns.contains($0) ? $0 : nil }
        phase = .mapping(columns: columns, mapping: mapping)
    }

    /// Monta o rascunho e o entrega ao editor, sem gravar (D12).
    public func confirmMapping() {
        guard case .mapping(_, let mapping) = phase, let pending else { return }
        self.pending = nil
        do {
            let result = try ExternalSurveyBuilder.build(table: pending.table, mapping: mapping, name: pending.name)
            presenter.presentDraft(result.draft)
            phase = .finished(warning: Self.warningMessage(rowErrors: result.rowErrors, hadFieldWarnings: result.hadFieldWarnings,
                                                           fileName: pending.fileName))
        } catch {
            phase = .failed(message: Self.message(for: error, fileName: pending.fileName))
        }
    }

    public func cancelImport() {
        pending = nil
        phase = .idle
    }

    /// XML leva todos os marcados; TXT e CSV só o primeiro, como o original (`ExportSurveyToDelimitedFile` recebe um).
    public func export(format: SurveyExportFormat, to url: URL) throws -> SurveyExportWarning? {
        let surveys = try source.surveysForExport(ids: selectedSurveyIDs)
        let resultsEngine = includeResults ? engine : nil
        let data: Data
        var warning: SurveyExportWarning?
        switch format {
        case .xml:
            data = SurveyXML.data(surveys, resultsEngine: resultsEngine)
        case .tabText, .semicolonCSV:
            guard let first = surveys.first else { return nil }
            data = SurveyDelimitedExport.data(first, resultsEngine: resultsEngine,
                                              format: format == .tabText ? .tabText : .semicolonCSV)
            if surveys.count > 1 { warning = .onlyFirstSurveyExported }
        }
        try data.write(to: url, options: .atomic)
        return warning
    }

    /// `Utils.DisplayImportError` em pt-BR; campo ausente lista os campos.
    public static func message(for failure: ImportFailure, fileName: String) -> String {
        let message = ChildExchangeModel.message(for: failure, fileName: fileName)
        guard case .missingField(let fields) = failure, !fields.isEmpty else { return message }
        return message + " \(L10n.Exchange.detail) " + fields.map { "\(L10n.SurveyExchange.field) '\($0.field)'" }
            .joined(separator: ", ") + "."
    }

    /// `DisplayImportWarningRows` com linha e campo de cada registro descartado, ou `DisplayImportWarningFields`; com os
    /// dois, a frase dos campos vem depois da lista de linhas.
    public static func warningMessage(rowErrors: [ImportFieldError], hadFieldWarnings: Bool, fileName: String) -> String? {
        let file = "\(L10n.SurveyExchange.filePrefix) '\(fileName)'"
        guard !rowErrors.isEmpty else {
            return hadFieldWarnings ? "\(file) \(L10n.SurveyExchange.fieldsInvalid)" : nil
        }
        var message = "\(file) \(L10n.SurveyExchange.rowsIgnored)\n\n"
            + rowErrors.map { "\(L10n.Exchange.line) \($0.line), \(L10n.SurveyExchange.field) '\($0.field)'." }.joined(separator: "\n")
        if hadFieldWarnings { message += "\n\n\(L10n.SurveyExchange.alsoFieldsInvalid)" }
        return message
    }

    // MARK: Privado

    private func importXML(_ data: Data, fileName: String) {
        let surveys: [ExchangeSurvey]
        do {
            surveys = try SurveyXML.read(data)
        } catch {
            phase = .failed(message: Self.message(for: error, fileName: fileName))
            return
        }
        do {
            _ = try sink.insertAll(surveys)
            phase = .finished(warning: nil)
        } catch {
            phase = .failed(message: "\(Self.prefix(fileName)) \(L10n.IndividualAssessment.databaseError) \(error)")
        }
    }

    private static func prefix(_ fileName: String) -> String {
        "\(L10n.Exchange.importFailedPrefix) '\(fileName)':"
    }
}
