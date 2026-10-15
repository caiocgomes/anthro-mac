/// Leitor escolhido pela extensão, como `NSMain.importFromFileToolStripMenuItem_Click` (design D2).
public enum SurveyFileKind: Equatable, Sendable {
    case delimited(fallbackSeparator: Character)
    case rec
    case dbf
    case xml

    public static func forFileExtension(_ fileExtension: String) -> SurveyFileKind { .xml }
}
