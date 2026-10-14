import AnthroStore
import Foundation

/// Valor de `IAAdditionalDataTemplate` do `.exe.config` original, desescapado uma vez; nunca a constante do app.
let iaTemplateXML = #"<Data><Cat ID="Maturation" Descr=""><Txt ID="Menarche/spermarche" Descr=""></Txt><Txt ID="Self-reported" Descr=""></Txt></Cat><Cat ID="Physical activity" Descr="hours per week"><Num Min="0" Max="140" ID="Sport" Descr="" /><Num Min="0" Max="140" ID="TV/computer" Descr="" /></Cat><Cat ID="Food" Descr=""><Num Min="0" Max="10" ID="Fruit&amp;veg portions / day" Descr="" /></Cat><Cat ID="Health" Descr=""><Txt ID="Blood pressure" Descr=""></Txt><Txt ID="Blood lipids" Descr=""></Txt></Cat></Data>"#

/// Caminho de um banco novo num diretório temporário próprio.
func temporaryDatabaseURL() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("anthro-additional-data-tests", isDirectory: true)
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("anthroplus.sqlite")
}
