/// Separador do texto delimitado (design D4 e D20): o padrão da extensão quando ele aparece fora de aspas na primeira
/// linha, como o original, que sempre o usava; senão, o mais frequente entre tabulação, ponto e vírgula e vírgula, e no
/// empate ou sem nenhum, o padrão. A detecção só cobre o arquivo que o original leria numa coluna só, como o CSV com
/// vírgula exportado por outros sistemas.
public enum SeparatorDetector {
    public static func detect(firstLine: String, fallback: Character) -> Character {
        var counts: [Character: Int] = ["\t": 0, ";": 0, ",": 0]
        var inQuotes = false
        for character in firstLine {
            if character == "\"" {
                inQuotes.toggle()
            } else if !inQuotes, counts[character] != nil {
                counts[character, default: 0] += 1
            }
        }
        if counts[fallback, default: 0] > 0 { return fallback }
        let best = counts.values.max() ?? 0
        let winners = counts.filter { $0.value == best }
        guard best > 0, winners.count == 1, let winner = winners.first?.key else { return fallback }
        return winner
    }
}
