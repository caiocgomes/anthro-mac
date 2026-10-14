import Foundation

public enum AboutInfo {
    /// `CFBundleShortVersionString` do bundle, ou "desenvolvimento" quando ausente.
    public static func version(bundle: Bundle) -> String {
        guard let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String, !version.isEmpty else {
            return L10n.About.developmentVersion
        }
        return version
    }
}
