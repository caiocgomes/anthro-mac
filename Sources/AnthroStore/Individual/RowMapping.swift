import AnthroCore
import Foundation

/// Conversões entre colunas e campos dos registros da Avaliação individual (design D1 e D3 da change 1).
extension SQLValue {
    static func text(_ value: String?) -> SQLValue {
        value.map { .text($0) } ?? .null
    }

    static func integer(_ value: Int64?) -> SQLValue {
        value.map { .integer($0) } ?? .null
    }

    static func integer(_ value: Int?) -> SQLValue {
        value.map { .integer(Int64($0)) } ?? .null
    }

    static func flag(_ value: Bool) -> SQLValue {
        .integer(value ? 1 : 0)
    }

    /// Sexo gravado como 1 = menino e 2 = menina (design D3 da change 1).
    static func sex(_ value: Sex) -> SQLValue {
        .integer(value == .boy ? 1 : 2)
    }
}

extension Row {
    func int64(_ column: String) -> Int64? {
        if case .integer(let value) = self[column] { return value }
        return nil
    }

    func int(_ column: String) -> Int? {
        int64(column).map(Int.init)
    }

    func string(_ column: String) -> String? {
        if case .text(let value) = self[column] { return value }
        return nil
    }

    func flag(_ column: String) -> Bool {
        int64(column) == 1
    }

    func decimal(_ column: String) -> Decimal? {
        self[column].decimalValue
    }

    func date(_ column: String) -> Date? {
        self[column].dateValue
    }

    func sex(_ column: String) -> Sex {
        int64(column) == 1 ? .boy : .girl
    }
}

/// `Global.StringAppendIfNotNull`: acrescenta o valor, precedido do separador se já houver texto.
func appendIfNotNull(_ text: inout String, _ value: String?, separator: String) {
    guard let value else { return }
    text += (text.isEmpty ? "" : separator) + value
}

/// `Global.NoDataLabel` (`Texts._Label_EmptyGraph` em pt-BR).
let noDataLabel = "(Sem dados)"

/// `" (ID)"` do original, com o ID vazio para registro ainda não gravado.
func idSuffix(_ id: Int64?) -> String {
    " (\(id.map(String.init) ?? ""))"
}
