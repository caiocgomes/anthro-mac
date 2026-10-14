import AnthroCore
import Foundation

/// Autoteste do app (`AnthroPlusApp --self-test`): confere os recursos embutidos sem abrir janela.
public enum SelfTest {
    public struct Outcome: Equatable, Sendable {
        public let passed: Bool
        public let message: String
    }

    public static func run() -> Outcome {
        guard let who = AnthroCoreResources.whoDirectory,
              FileManager.default.fileExists(atPath: who.appendingPathComponent("README.txt").path) else {
            return Outcome(passed: false, message: L10n.SelfTest.missingResources)
        }
        return Outcome(passed: true, message: L10n.SelfTest.ok)
    }
}
