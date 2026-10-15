import AnthroCore
import Foundation

/// `IAMain.GenerateChildReport` em pt-BR (design D12): cabeçalho da criança, 12 colunas por visita em ordem cronológica
/// e a nota sobre padrões e referência, em UTF-16 LE com BOM e CRLF.
public enum ChildReport {
    /// Rótulos de `Texts.resx` traduzidos; ficam aqui porque o `AnthroIO` não enxerga o `L10n` do `AnthroFeatures`, que
    /// os reexporta em `L10n.Exchange`.
    public enum Labels {
        public static let title = "Avaliação individual"
        public static let firstName = "Nome"
        public static let lastName = "Sobrenome"
        public static let dateOfBirth = "Data de nascimento"
        public static let male = "Masculino"
        public static let female = "Feminino"
        public static let results = "Resultados"
        public static let columns = ["Nº", "Data da visita", "ID do observador", "Peso (kg)", "Edema (s/n)", "Deitado (s/n)",
                                     "Comp./alt. (cm)", "Idade", "Idade (meses)", "P/I z", "E/I z", "IMC/I z"]
        public static let yearSuffix = "a"
        public static let monthSuffix = "m"
        public static let yes = "s"
        public static let no = "n"
        public static let footnote = "Os z-scores se baseiam nos padrões da OMS (nascimento a 60 meses) e na referência OMS 2007 (61 meses a 19 anos)."
        /// Nome do arquivo quando a criança não tem nome nem sobrenome.
        public static let untitledFileName = "Avaliação individual"
    }

    public static func text(for child: ExchangeChild) -> String {
        var text = "\(Labels.title)\r\n\r\n"
        text += "\(Labels.firstName):\t\(child.firstName ?? "")\r\n"
        text += "\(Labels.lastName):\t\(child.lastName ?? "")\r\n"
        text += "\(Labels.dateOfBirth):\t\(shortDate(child.dateOfBirth))\r\n"
        text += "\(child.sex == .boy ? Labels.male : Labels.female)\r\n\r\n"
        text += "\(Labels.results):\r\n\r\n"
        text += Labels.columns.joined(separator: "\t") + "\r\n"
        let visits = child.visits.sorted { $0.date < $1.date }
        for (index, visit) in visits.enumerated() {
            text += visitFields(visit, number: index + 1, dateOfBirth: child.dateOfBirth).joined(separator: "\t") + "\r\n"
        }
        return text + "\r\n" + Labels.footnote
    }

    /// `StreamWriter` com `Encoding.Unicode`: UTF-16 LE com BOM.
    public static func data(for child: ExchangeChild) -> Data {
        var data = Data([0xFF, 0xFE])
        for unit in text(for: child).utf16 {
            data.append(UInt8(unit & 0xFF))
            data.append(UInt8(unit >> 8))
        }
        return data
    }

    /// `<sobrenome>, <nome>.txt`, sem a vírgula quando falta um dos dois; barras e dois-pontos viram hífen.
    public static func suggestedFileName(for child: ExchangeChild) -> String {
        let names = [child.lastName, child.firstName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let base = names.isEmpty ? Labels.untitledFileName : names.joined(separator: ", ")
        return base.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-") + ".txt"
    }

    // MARK: Linha de visita

    private static func visitFields(_ visit: ExchangeVisit, number: Int, dateOfBirth: Date) -> [String] {
        let months = (try? AgeMath.ageInDays(birth: dateOfBirth, visit: visit.date)).map(AgeMath.daysToMonths)
        let wholeMonths = months.map { NSDecimalNumber(decimal: FieldParser.truncate($0, places: 0)).intValue }
        return [
            String(number), shortDate(visit.date), ExchangeDefaults.createdBy,
            FieldWriter.decimal(visit.weight, style: .comma), visit.hasOedema ? Labels.yes : Labels.no,
            visit.isRecumbent ? Labels.yes : Labels.no, FieldWriter.decimal(visit.height, style: .comma),
            wholeMonths.map { "\($0 / 12)\(Labels.yearSuffix) \($0 % 12)\(Labels.monthSuffix)" } ?? "",
            months.map { FieldWriter.decimal(FieldParser.truncate($0, places: 1), style: .comma) } ?? "",
            FieldWriter.decimal(visit.results?.weightForAgeZ, style: .comma),
            FieldWriter.decimal(visit.results?.lengthOrHeightForAgeZ, style: .comma),
            FieldWriter.decimal(visit.results?.bmiForAgeZ, style: .comma),
        ]
    }

    /// `ToShortDateString` em pt-BR, no dia de calendário do usuário.
    private static func shortDate(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%02d/%02d/%04d", parts.day ?? 1, parts.month ?? 1, parts.year ?? 1)
    }
}
