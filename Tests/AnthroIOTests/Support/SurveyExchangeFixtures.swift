import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Tabelas, registros e XML de inquérito montados nos testes de troca de dados do inquérito.
enum SurveyExchangeFixtures {
    static func table(_ columns: [String], _ rows: [[String]]) -> ImportedTable {
        ImportedTable(columns: columns, rows: rows)
    }

    static func record(sex: Sex = .girl, visit: String? = "2021-04-01", birth: String? = "2016-03-15", months: String? = nil,
                       weight: String? = "18.4", height: String? = "110", displayID: Int? = 1,
                       weightingFactor: String = "1") -> SurveyRecord {
        var record = SurveyRecord(sex: sex, weightingFactor: d(weightingFactor))
        record.visitDate = visit.map(day)
        record.dateOfBirth = birth.map(day)
        record.ageInMonths = months.map(d)
        record.weight = weight.map(d)
        record.lengthOrHeight = height.map(d)
        record.displayID = displayID
        record.hasOedema = false
        record.additionalDataXML = "<Data />"
        return record
    }

    /// Documento `<Surveys>` com o cabeçalho do original.
    static func xml(_ surveys: String) -> Data {
        Data(("<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>\n<Surveys>\n" + surveys + "\n</Surveys>\n").utf8)
    }

    /// `<Survey>` com os atributos dados e os registros.
    static func survey(name: String = "Escola A", options: String = "&lt;Opt /&gt;", records: [String]) -> String {
        "<Survey Name=\"\(name)\" Notes=\"\" Options=\"\(options)\" CreatedBy=\"obs1\">"
            + (records.isEmpty ? "" : "<Records>" + records.joined() + "</Records>") + "</Survey>"
    }

    /// `<Record>` com os atributos obrigatórios e os extras ou substitutos dados (valor `nil` remove o atributo).
    static func recordXML(_ attributes: [String: String?] = [:]) -> String {
        var values: [(String, String?)] = [("Date", "01-04-2021 00:00:00"), ("Cluster", "1"), ("Team", ""), ("DisplayID", "1"),
                                           ("Household", "1"), ("WeightingFactor", "1"), ("FirstName", "Ana"), ("LastName", ""),
                                           ("DateOfBirth", ""), ("DateOfBirthIsApprox", "0"), ("Age", "70"), ("Sex", "0"),
                                           ("Weight", "18.4"), ("Height", "110"), ("IsRecumbent", "0"), ("HasOedema", "0"),
                                           ("Notes", ""), ("AdditionalData", "&lt;Data /&gt;"), ("CreatedBy", "obs1")]
        for (key, value) in attributes {
            if let index = values.firstIndex(where: { $0.0 == key }) { values[index].1 = value } else { values.append((key, value)) }
        }
        return "<Record " + values.compactMap { key, value in value.map { "\(key)=\"\($0)\"" } }.joined(separator: " ") + " />"
    }

    static func lines(_ data: Data) -> [String] {
        var text = String(decoding: data, as: UTF8.self)
        if text.hasPrefix("\u{FEFF}") { text.removeFirst() }
        var lines = text.components(separatedBy: "\r\n")
        if lines.last == "" { lines.removeLast() }
        return lines
    }
}

/// Falha esperada de formato inválido, com qualquer detalhe.
func expectInvalidStructure(_ body: () throws(ImportFailure) -> Void, sourceLocation: SourceLocation = #_sourceLocation) {
    do {
        try body()
        Issue.record("expected ImportFailure.invalidStructure, got no error", sourceLocation: sourceLocation)
    } catch {
        guard case .invalidStructure = error else {
            Issue.record("expected ImportFailure.invalidStructure, got \(error)", sourceLocation: sourceLocation)
            return
        }
    }
}
