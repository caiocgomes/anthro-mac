import AnthroCore
import Foundation

/// Autoteste do app (`AnthroPlusApp --self-test`): confere os recursos embutidos sem abrir janela, inclusive
/// as tabelas da OMS lidas de dentro do bundle (design D13 da add-anthropometric-calculator).
public enum SelfTest {
    public struct Outcome: Equatable, Sendable {
        public let passed: Bool
        public let message: String
    }

    /// Linhas dos padrões por indicador e sexo: 0 a 1856 dias.
    private static let standardsRows = 1857

    public static func run(loadTables: () throws -> GrowthReferenceTables = { try GrowthReferenceTables.bundled() }) -> Outcome {
        guard let who = AnthroCoreResources.whoDirectory,
              FileManager.default.fileExists(atPath: who.appendingPathComponent("README.txt").path) else {
            return Outcome(passed: false, message: L10n.SelfTest.missingResources)
        }
        let tables: GrowthReferenceTables
        do {
            tables = try loadTables()
        } catch {
            return Outcome(passed: false, message: "\(L10n.SelfTest.missingTables) \(error)")
        }
        let wrong = Indicator.allCases.flatMap { indicator in
            Sex.allCases.compactMap { sex in
                tables.rowCount(indicator, range: .standards, sex: sex) == standardsRows ? nil : "\(indicator) \(sex)"
            }
        }
        guard wrong.isEmpty else {
            return Outcome(passed: false, message: "\(L10n.SelfTest.wrongRowCount) \(wrong.joined(separator: ", "))")
        }
        return Outcome(passed: true, message: L10n.SelfTest.ok)
    }
}
