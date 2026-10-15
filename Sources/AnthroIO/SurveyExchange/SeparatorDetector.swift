/// Separador mais frequente fora de aspas na primeira linha; empate ou nenhum usa o padrão da extensão (design D4).
public enum SeparatorDetector {
    public static func detect(firstLine: String, fallback: Character) -> Character { "\u{0}" }
}
