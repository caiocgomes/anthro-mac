import AnthroCore
import AnthroFeatures
import Foundation

/// Valor de `IAAdditionalDataTemplate` do `.exe.config` original, desescapado uma vez; nunca a constante do app.
let iaTemplateXML = #"<Data><Cat ID="Maturation" Descr=""><Txt ID="Menarche/spermarche" Descr=""></Txt><Txt ID="Self-reported" Descr=""></Txt></Cat><Cat ID="Physical activity" Descr="hours per week"><Num Min="0" Max="140" ID="Sport" Descr="" /><Num Min="0" Max="140" ID="TV/computer" Descr="" /></Cat><Cat ID="Food" Descr=""><Num Min="0" Max="10" ID="Fruit&amp;veg portions / day" Descr="" /></Cat><Cat ID="Health" Descr=""><Txt ID="Blood pressure" Descr=""></Txt><Txt ID="Blood lipids" Descr=""></Txt></Cat></Data>"#

/// Títulos em pt-BR das 19 colunas fixas da tabela do inquérito, escritos por extenso.
let fixedSurveyColumnTitles = ["Data da pesquisa", "Conglomerado", "Equipe", "ID", "Domicílio", "Sexo",
                               "Data de nascimento", "Idade (d)", "Idade (m)", "Peso (kg)", "Edema", "Deitado",
                               "Estatura (cm)", "z P/I", "z E/I", "z IMC/I", "Flag", "Fator de peso",
                               "Nascimento estimado"]

func textVariable(_ identifier: String, _ value: String? = nil) -> AdditionalDataVariable {
    AdditionalDataVariable(identifier: identifier, kind: .text(value))
}

func numberVariable(_ identifier: String, value: Decimal? = nil, minimum: Decimal? = nil,
                    maximum: Decimal? = nil) -> AdditionalDataVariable {
    AdditionalDataVariable(identifier: identifier, kind: .number(value: value, minimum: minimum, maximum: maximum))
}

extension SurveyTableColumn {
    var isAdditional: Bool {
        if case .additional = self { true } else { false }
    }
}
