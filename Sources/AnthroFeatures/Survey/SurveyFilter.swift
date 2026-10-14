import Foundation

/// Condições do `NSFilterDialog`, na ordem da lista.
public enum FilterCondition: Int, CaseIterable, Sendable {
    case equal, notEqual, greaterOrEqual, lessOrEqual, range

    public var symbol: String {
        switch self {
        case .equal: "="
        case .notEqual: "≠"
        case .greaterOrEqual: "≥"
        case .lessOrEqual: "≤"
        case .range: L10n.Survey.Filter.range
        }
    }
}

public struct SurveyFilter: Sendable, Equatable {
    public var column: SurveyTableColumn
    public var condition: FilterCondition
    public var value1: String
    public var value2: String

    public init(column: SurveyTableColumn, condition: FilterCondition, value1: String, value2: String = "") {
        self.column = column
        self.condition = condition
        self.value1 = value1
        self.value2 = value2
    }
}

/// Decisão de manter uma célula pelo texto exibido, como `NSMain.FilterRecords` (design D7): números quando célula e
/// valor são números (vírgula ou ponto); senão igual e diferente comparam texto em minúsculas com o valor aparado, e as
/// demais condições comparam datas dd/MM/aaaa, ocultando a célula quando alguma data não é legível. No intervalo de
/// datas, limite vazio fica aberto (lógica do IL, não a da decompilação do ILSpy).
public enum SurveyFilterEvaluator {
    public static func keeps(cellText: String, condition: FilterCondition, value1: String, value2: String) -> Bool {
        if let cell = ClinicalFormat.parseDecimal(cellText), let first = ClinicalFormat.parseDecimal(value1) {
            switch condition {
            case .equal: return cell == first
            case .notEqual: return cell != first
            case .greaterOrEqual: return cell >= first
            case .lessOrEqual: return cell <= first
            case .range:
                // Segundo limite que não é número lança no original e cai na comparação de datas, abaixo.
                if let second = ClinicalFormat.parseDecimal(value2) { return cell >= first && cell <= second }
            }
        }
        let value = value1.trimmingCharacters(in: .whitespaces).lowercased()
        switch condition {
        case .equal:
            return cellText.lowercased() == value
        case .notEqual:
            return cellText.lowercased() != value
        case .greaterOrEqual:
            guard let cell = date(cellText), let limit = date(value1) else { return false }
            return cell >= limit
        case .lessOrEqual:
            guard let cell = date(cellText), let limit = date(value1) else { return false }
            return cell <= limit
        case .range:
            guard let cell = date(cellText) else { return false }
            if !value1.isEmpty {
                guard let lower = date(value1), cell >= lower else { return false }
            }
            if !value2.isEmpty {
                guard let upper = date(value2), cell <= upper else { return false }
            }
            return true
        }
    }

    /// Data dd/MM/aaaa (dia e mês com um ou dois dígitos) como dia de calendário; `nil` para texto ou dia inexistente.
    private static func date(_ text: String) -> CalendarDay? {
        let parts = text.trimmingCharacters(in: .whitespaces).split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 3, (1...2).contains(parts[0].count), (1...2).contains(parts[1].count), parts[2].count == 4,
              let day = Int(parts[0]), let month = Int(parts[1]), let year = Int(parts[2]) else { return nil }
        let components = DateComponents(year: year, month: month, day: day)
        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: components),
              calendar.dateComponents([.year, .month, .day], from: date) == components else { return nil }
        return CalendarDay(year: year, month: month, day: day)
    }

    private struct CalendarDay: Comparable {
        let year: Int
        let month: Int
        let day: Int

        static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
            (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
        }
    }
}
