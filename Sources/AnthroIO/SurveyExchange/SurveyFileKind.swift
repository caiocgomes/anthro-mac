/// Leitor escolhido pela extensão, como `NSMain.importFromFileToolStripMenuItem_Click` (design D2): `.txt` com
/// tabulação, `.csv` com ponto e vírgula como padrão do separador, `.rec`, `.dbf`, e qualquer outra como XML.
public enum SurveyFileKind: Equatable, Sendable {
    case delimited(fallbackSeparator: Character)
    case rec
    case dbf
    case xml

    public static func forFileExtension(_ fileExtension: String) -> SurveyFileKind {
        switch fileExtension.lowercased() {
        case "txt": .delimited(fallbackSeparator: "\t")
        case "csv": .delimited(fallbackSeparator: ";")
        case "rec": .rec
        case "dbf": .dbf
        default: .xml
        }
    }
}
