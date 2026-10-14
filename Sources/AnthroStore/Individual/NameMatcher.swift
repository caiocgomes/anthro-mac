/// Curingas `*` e `?` de `DBHelper.ReplaceWildcards`, sem diferenciar maiúsculas e diferenciando acentos (design D5).
public enum NameMatcher {
    public static func matches(pattern: String, value: String?) -> Bool {
        false
    }
}
