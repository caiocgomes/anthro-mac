import AnthroCore
import Foundation

public enum SurveyStoreError: Error, Equatable {
    case nameRequired
    case notFound(Int64)
}

/// Inquéritos e registros no banco (`Surveys` e `Records` do DAL original, design D2 e D3).
public struct SurveyRepository: Sendable {
    private let database: AnthroDatabase

    private static let surveyColumns = "id, name, notes, additional_data_def, options, is_archived"
    private static let recordColumns = """
        id, visit_date, cluster, team, display_id, household, weighting_factor, first_name, last_name, date_of_birth,
        dob_is_approx, age_months, sex, weight, length_or_height, measured_recumbent, has_oedema, notes, additional_data
        """

    public init(database: AnthroDatabase) {
        self.database = database
    }

    /// `Surveys.GetList`: ativos ou arquivados, por nome (sem diferenciar maiúsculas) e, no empate, por identificador.
    public func list(archived: Bool) throws -> [Survey] {
        try database.query("SELECT \(Self.surveyColumns) FROM surveys WHERE is_archived = ? ORDER BY name COLLATE NOCASE, id",
                           [.flag(archived)]).map(Self.survey)
    }

    public func survey(id: Int64) throws -> Survey {
        guard let row = try database.query("SELECT \(Self.surveyColumns) FROM surveys WHERE id = ?", [.integer(id)]).first
        else { throw SurveyStoreError.notFound(id) }
        return try Self.survey(row)
    }

    /// Registros na ordem de inclusão (`position`).
    public func records(surveyID: Int64) throws -> [SurveyRecord] {
        try database.query("SELECT \(Self.recordColumns) FROM records WHERE survey_id = ? ORDER BY position, id",
                           [.integer(surveyID)]).map(Self.record)
    }

    /// `BaseDataList.ApplyDataChanges` numa transação: inquérito incluído ou atualizado, registros que saíram excluídos,
    /// os demais atualizados ou incluídos com `position` igual ao índice. Nome obrigatório depois de remover espaços das
    /// pontas (`NSMain.SaveCurrentSurvey`); notas vazias viram `nil`.
    public func save(_ survey: Survey, records: [SurveyRecord]) throws -> (survey: Survey, records: [SurveyRecord]) {
        var saved = survey
        saved.name = survey.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !saved.name.isEmpty else { throw SurveyStoreError.nameRequired }
        saved.notes = survey.notes.flatMap { notes in
            let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return try database.transaction {
            let values: [SQLValue] = [.text(saved.name), .text(saved.notes), .text(saved.additionalDataDefinitionXML),
                                      .text(saved.options.xml())]
            if let id = saved.id {
                try database.execute(
                    """
                    UPDATE surveys SET name = ?, notes = ?, additional_data_def = ?, options = ?,
                        updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
                    WHERE id = ?
                    """, values + [.integer(id)])
                guard case .integer(1) = try database.query("SELECT changes() AS n").first?["n"] else {
                    throw StoreError.recordNotFound(table: "surveys", id: id)
                }
            } else {
                try database.execute("INSERT INTO surveys(name, notes, additional_data_def, options, is_archived) VALUES (?, ?, ?, ?, ?)",
                                     values + [.flag(saved.isArchived)])
                saved.id = database.lastInsertRowID()
            }
            let surveyID = saved.id!
            let stored = Set(try database.query("SELECT id FROM records WHERE survey_id = ?", [.integer(surveyID)])
                .compactMap { $0.int64("id") })
            let kept = Set(records.compactMap(\.id)).intersection(stored)
            for removed in stored.subtracting(kept) {
                try database.execute("DELETE FROM records WHERE id = ?", [.integer(removed)])
            }
            var savedRecords: [SurveyRecord] = []
            for (position, record) in records.enumerated() {
                var savedRecord = record
                let columns = Self.recordValues(record) + [.integer(Int64(position))]
                if let id = record.id, kept.contains(id) {
                    try database.execute(
                        """
                        UPDATE records SET visit_date = ?, cluster = ?, team = ?, display_id = ?, household = ?,
                            weighting_factor = ?, first_name = ?, last_name = ?, date_of_birth = ?, dob_is_approx = ?,
                            age_months = ?, sex = ?, weight = ?, length_or_height = ?, measured_recumbent = ?,
                            has_oedema = ?, notes = ?, additional_data = ?, position = ?,
                            updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
                        WHERE id = ?
                        """, columns + [.integer(id)])
                } else {
                    try database.execute(
                        """
                        INSERT INTO records(visit_date, cluster, team, display_id, household, weighting_factor, first_name,
                            last_name, date_of_birth, dob_is_approx, age_months, sex, weight, length_or_height,
                            measured_recumbent, has_oedema, notes, additional_data, position, survey_id)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """, columns + [.integer(surveyID)])
                    savedRecord.id = database.lastInsertRowID()
                }
                savedRecords.append(savedRecord)
            }
            return (saved, savedRecords)
        }
    }

    public func setArchived(_ ids: [Int64], archived: Bool) throws {
        try database.transaction {
            for id in ids {
                try database.execute(
                    "UPDATE surveys SET is_archived = ?, updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now') WHERE id = ?",
                    [.flag(archived), .integer(id)])
            }
        }
    }

    /// `Surveys.Delete`: os registros saem pela exclusão em cascata da migração 3.
    public func delete(_ ids: [Int64]) throws {
        try database.transaction {
            for id in ids {
                try database.execute("DELETE FROM surveys WHERE id = ?", [.integer(id)])
            }
        }
    }

    // MARK: Mapeamento

    private static func survey(_ row: Row) throws -> Survey {
        Survey(id: row.int64("id"), name: row.string("name") ?? "", notes: row.string("notes"),
               additionalDataDefinitionXML: row.string("additional_data_def"),
               options: try SurveyOptions(xml: row.string("options") ?? ""), isArchived: row.flag("is_archived"))
    }

    /// Colunas de `records` na ordem dos comandos de `save`, sem `position` e `survey_id`.
    private static func recordValues(_ record: SurveyRecord) -> [SQLValue] {
        [SQLValue(record.visitDate), .integer(record.cluster), .integer(record.team), .integer(record.displayID),
         .integer(record.household), SQLValue(record.weightingFactor), .text(record.firstName), .text(record.lastName),
         SQLValue(record.dateOfBirth), .flag(record.dateOfBirthIsApprox), SQLValue(record.ageInMonths), .sex(record.sex),
         SQLValue(record.weight), SQLValue(record.lengthOrHeight), .flag(record.measuredRecumbent),
         record.hasOedema.map(SQLValue.flag) ?? .null, .text(record.notes), .text(record.additionalDataXML)]
    }

    private static func record(_ row: Row) -> SurveyRecord {
        var record = SurveyRecord(id: row.int64("id"), sex: row.sex("sex"), weightingFactor: row.decimal("weighting_factor") ?? 1)
        record.visitDate = row.date("visit_date")
        record.cluster = row.int("cluster")
        record.team = row.int("team")
        record.displayID = row.int("display_id")
        record.household = row.int("household")
        record.firstName = row.string("first_name")
        record.lastName = row.string("last_name")
        record.dateOfBirth = row.date("date_of_birth")
        record.dateOfBirthIsApprox = row.flag("dob_is_approx")
        record.ageInMonths = row.decimal("age_months")
        record.weight = row.decimal("weight")
        record.lengthOrHeight = row.decimal("length_or_height")
        record.measuredRecumbent = row.flag("measured_recumbent")
        record.hasOedema = row.int64("has_oedema").map { $0 == 1 }
        record.notes = row.string("notes")
        record.additionalDataXML = row.string("additional_data")
        return record
    }
}
