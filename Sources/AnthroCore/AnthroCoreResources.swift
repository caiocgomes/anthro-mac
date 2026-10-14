import Foundation

/// Acesso ao bundle de recursos do `AnthroCore`.
///
/// O acessor `Bundle.module` gerado pelo SwiftPM procura o bundle na raiz do `.app` (onde o `codesign`
/// recusa arquivos) e, se não encontra, cai no caminho absoluto do `.build` da máquina de desenvolvimento.
/// Dentro de um `.app`, portanto, só vale `Contents/Resources`, onde `scripts/build-app.sh` copia o bundle;
/// fora dele (testes, `swift run`) vale o `Bundle.module`.
public enum AnthroCoreResources {
    static let bundleName = "AnthroPlus_AnthroCore.bundle"

    public static var bundle: Bundle? {
        let main = Bundle.main
        if main.bundleURL.pathExtension == "app" {
            return main.resourceURL.flatMap { Bundle(url: $0.appendingPathComponent(bundleName)) }
        }
        return Bundle.module
    }

    /// Diretório `who` com as tabelas da OMS, ou `nil` se o bundle de recursos não foi encontrado.
    public static var whoDirectory: URL? {
        bundle?.url(forResource: "who", withExtension: nil)
    }
}
