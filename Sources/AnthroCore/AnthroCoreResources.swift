import Foundation

/// Acesso público ao bundle de recursos do `AnthroCore`, usado pelo autoteste do app.
public enum AnthroCoreResources {
    /// Diretório `who` com as tabelas da OMS, ou `nil` se o bundle de recursos não foi encontrado.
    public static var whoDirectory: URL? {
        Bundle.module.url(forResource: "who", withExtension: nil)
    }
}
