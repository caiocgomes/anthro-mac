import Foundation

/// Curingas `*` e `?` de `DBHelper.ReplaceWildcards`, sem diferenciar maiúsculas e diferenciando acentos (design D5):
/// o padrão vira uma expressão regular ancorada, com o resto do texto escapado, comparada em NFC.
public enum NameMatcher {
    public static func matches(pattern: String, value: String?) -> Bool {
        guard let value else { return false }
        var expression = "^"
        for character in pattern.precomposedStringWithCanonicalMapping {
            switch character {
            case "*": expression += ".*"
            case "?": expression += "."
            default: expression += NSRegularExpression.escapedPattern(for: String(character))
            }
        }
        expression += "$"
        guard let regex = try? NSRegularExpression(pattern: expression, options: [.caseInsensitive, .dotMatchesLineSeparators])
        else { return false }
        let target = value.precomposedStringWithCanonicalMapping
        return regex.firstMatch(in: target, range: NSRange(target.startIndex..., in: target)) != nil
    }
}
