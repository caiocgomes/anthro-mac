/// Separador do texto delimitado (design D4): o mais frequente entre tabulação, ponto e vírgula e vírgula, contados
/// fora de aspas na primeira linha; empate ou nenhum usa o padrão da extensão. O original usa só o padrão; a detecção
/// cobre o CSV com vírgula exportado por outros sistemas.
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
        let best = counts.values.max() ?? 0
        let winners = counts.filter { $0.value == best }
        guard best > 0, winners.count == 1, let winner = winners.first?.key else { return fallback }
        return winner
    }
}
