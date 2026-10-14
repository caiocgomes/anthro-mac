import AnthroCore
import AnthroIO
import Foundation
import Testing

/// Meio-dia do dia de calendário do usuário, a partir de "AAAA-MM-DD" (a normalização do app).
func day(_ text: String) -> Date {
    let parts = text.split(separator: "-").map { Int($0)! }
    return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))!
}

/// Dia de calendário de uma data como "AAAA-MM-DD".
func ymd(_ date: Date?) -> String? {
    guard let date else { return nil }
    let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
}

/// Decimal a partir de texto com ponto, sem passar por Double.
func d(_ text: String) -> Decimal {
    Decimal(string: text, locale: Locale(identifier: "en_US_POSIX"))!
}

/// Dados de teste: Ana Silva, nascida em 2016-03-15, menina.
enum ExchangeFixtures {
    static func ana(displayID: Int? = 12, lastName: String? = "Silva", notes: String? = nil,
                    mother: ExchangePerson? = nil, father: ExchangePerson? = nil, address: ExchangeAddress? = nil,
                    visits: [ExchangeVisit] = []) -> ExchangeChild {
        ExchangeChild(displayID: displayID, firstName: "Ana", lastName: lastName, dateOfBirth: day("2016-03-15"),
                      sex: .girl, notes: notes, mother: mother, father: father, address: address, visits: visits)
    }

    static func visit(_ date: String, weight: String? = nil, height: String? = nil, recumbent: Bool = false,
                      oedema: Bool = false, notes: String? = nil, additionalData: AdditionalData? = nil,
                      results: ExchangeResults? = nil) -> ExchangeVisit {
        ExchangeVisit(date: day(date), weight: weight.map(d), height: height.map(d), isRecumbent: recumbent,
                      hasOedema: oedema, notes: notes, additionalData: additionalData, results: results)
    }

    /// Visita `days` dias depois do nascimento de Ana.
    static func visit(daysAfterBirth days: Int, weight: String? = nil, height: String? = nil, recumbent: Bool = false,
                      oedema: Bool = false, results: ExchangeResults? = nil) -> ExchangeVisit {
        ExchangeVisit(date: Calendar.current.date(byAdding: .day, value: days, to: day("2016-03-15"))!,
                      weight: weight.map(d), height: height.map(d), isRecumbent: recumbent, hasOedema: oedema,
                      results: results)
    }

    static func fixture(_ name: String) throws -> Data {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }

    /// Documento `<Children>` com o cabeçalho do original e os elementos dados.
    static func xml(_ children: String) -> Data {
        Data(("<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>\n<Children>\n" + children + "\n</Children>\n").utf8)
    }

    /// `<Child>` com os atributos obrigatórios de Ana, os extras ou substitutos dados e o conteúdo interno.
    static func child(_ attributes: [String: String?] = [:], inner: String = "") -> String {
        var values: [(String, String?)] = [("DisplayID", "12"), ("FirstName", "Ana"), ("LastName", "Silva"),
                                           ("DateOfBirth", "15-03-2016 00:00:00"), ("DateOfBirthIsApprox", "0"),
                                           ("Sex", "0"), ("Notes", ""), ("CreatedBy", "obs1")]
        for (key, value) in attributes {
            if let index = values.firstIndex(where: { $0.0 == key }) { values[index].1 = value } else { values.append((key, value)) }
        }
        let text = values.compactMap { key, value in value.map { "\(key)=\"\($0)\"" } }.joined(separator: " ")
        return inner.isEmpty ? "<Child \(text) />" : "<Child \(text)>\(inner)</Child>"
    }

    /// `<Visit>` com os atributos obrigatórios e os extras ou substitutos dados (valor `nil` remove o atributo).
    static func visitXML(_ date: String, _ attributes: [String: String?] = [:]) -> String {
        var values: [(String, String?)] = [("Date", date), ("Weight", "18,4"), ("Height", "110"), ("IsRecumbent", "0"),
                                           ("HasOedema", "0"), ("Notes", ""), ("AdditionalData", "&lt;Data /&gt;"),
                                           ("CreatedBy", "obs1")]
        for (key, value) in attributes {
            if let index = values.firstIndex(where: { $0.0 == key }) { values[index].1 = value } else { values.append((key, value)) }
        }
        return "<Visit " + values.compactMap { key, value in value.map { "\(key)=\"\($0)\"" } }.joined(separator: " ") + " />"
    }

    static func visits(_ items: String...) -> String {
        "<Visits>" + items.joined() + "</Visits>"
    }

    /// Linhas e campos de um arquivo delimitado em UTF-8 (com ou sem BOM), separando ingenuamente pelo separador.
    static func table(_ data: Data, separator: Character) -> [[String]] {
        var text = String(decoding: data, as: UTF8.self)
        if text.hasPrefix("\u{FEFF}") { text.removeFirst() }
        var lines = text.components(separatedBy: "\r\n")
        if lines.last == "" { lines.removeLast() }
        return lines.map { $0.split(separator: separator, omittingEmptySubsequences: false).map(String.init) }
    }

    /// Valor da coluna `name` na linha `row` (0 é a primeira linha de dados).
    static func cell(_ table: [[String]], _ name: String, row: Int = 0) -> String? {
        guard let header = table.first, let column = header.firstIndex(of: name), table.count > row + 1,
              table[row + 1].indices.contains(column) else { return nil }
        return table[row + 1][column]
    }
}

/// Falha esperada de formato inválido (`ImportFailure.invalidStructure`), com qualquer detalhe.
func expectInvalidStructure(_ data: Data, sourceLocation: SourceLocation = #_sourceLocation) {
    do {
        let children = try ChildXML.read(data)
        Issue.record("expected ImportFailure.invalidStructure, got \(children.count) children", sourceLocation: sourceLocation)
    } catch {
        guard case .invalidStructure = error else {
            Issue.record("expected ImportFailure.invalidStructure, got \(error)", sourceLocation: sourceLocation)
            return
        }
    }
}
