import AnthroCore

extension L10n {
    /// Nomes dos indicadores (`_Label_W4A`, `_Label_L4A`, `_Label_H4A`, `_Label_BMI4A` do original).
    public enum Indicators {
        public static let weightForAge = "Peso para idade"
        public static let lengthForAge = "Comprimento para idade"
        public static let heightForAge = "Estatura para idade"
        public static let lengthOrHeightForAge = "Comprimento/estatura para idade"
        public static let bmiForAge = "IMC para idade"

        /// `isLength` nulo usa o nome genérico "Comprimento/estatura para idade".
        public static func title(_ indicator: Indicator, isLength: Bool?) -> String {
            switch indicator {
            case .weightForAge: weightForAge
            case .lengthOrHeightForAge:
                switch isLength {
                case true?: lengthForAge
                case false?: heightForAge
                case nil: lengthOrHeightForAge
                }
            case .bmiForAge: bmiForAge
            }
        }
    }

    /// Rótulos de `GetLocalizedAgeFromMonths`.
    public enum Age {
        public static let label = "Idade"
        public static let yearSuffix = "a"
        public static let monthSuffix = "m"
    }

    public enum Calculator {
        public static let dateOfBirth = "Data de nascimento"
        public static let approximateDate = "Data aproximada"
        public static let dateOfVisit = "Data da visita"
        public static let sex = "Sexo"
        public static let female = "Feminino"
        public static let male = "Masculino"
        public static let weight = "Peso (kg)"
        public static let lengthOrHeight = "Comprimento/estatura (cm)"
        public static let measurement = "Medida"
        public static let recumbent = "Deitado"
        public static let standing = "Em pé"
        public static let oedema = "Edema"
        public static let no = "Não"
        public static let yes = "Sim"
        public static let bmi = "IMC"
        public static let results = "Resultados"
        public static let zScore = "Z-score"
        public static let percentile = "Percentil"
        public static let showChart = "Mostrar gráfico"
        public static let child = "Criança"
        public static let measurements = "Medidas"
        public static let kilograms = "kg"
        public static let centimeters = "cm"
        public static let measurementHint = "A escolha entre deitado e em pé só existe abaixo de 11 meses de idade."
        public static let tablesUnavailable = "Tabelas da OMS indisponíveis"
        public static let invalidValue = "Valor inválido"
        /// "Fora do intervalo: {mín} a {máx}".
        public static let outOfRangePrefix = "Fora do intervalo:"
        public static let rangeSeparator = "a"
    }

    public enum Chart {
        public static let title = "Padrões de crescimento da OMS (nascimento a 60 meses), referência OMS 2007 (61 meses a 19 anos)"
        public static let noData = "(Sem dados)"
        public static let xAxis = "Idade (meses)"
        public static let outOfRangeSuffix = " (valor(es) fora do intervalo)"
        public static let weightAxis = "Peso (kg)"
        public static let lengthOrHeightAxis = "Comprimento/estatura (cm)"
        public static let bmiAxis = "Índice de massa corporal"
        public static let median = "Mediana"
        public static let standardDeviation = "DP"
        /// `_Label_Percentile3rd` a `_Label_Percentile97th`.
        public static let percentileLabels = ["3º", "15º", "50º", "85º", "97º"]
        public static let lengthMarker = "COMPRIMENTO"
        public static let heightMarker = "ESTATURA"
        public static let zScoreMode = "Z-score"
        public static let percentileMode = "Percentil"
        public static let legendZScore = "z-score"
        public static let legendPercentile = "Percentil"
        public static let indicator = "Indicador"
        public static let mode = "Modo"
        public static let multiplePoints = "Vários pontos"
        public static let resetZoom = "Restaurar"
        public static let copy = "Copiar"
        public static let export = "Exportar"
        public static let exportPDF = "Exportar PDF…"
        public static let exportPNG = "Exportar PNG…"
        public static let print = "Imprimir…"
        public static let close = "Fechar"
        public static let exportFailed = "Não foi possível exportar o gráfico."
        public static let zoomHint = "Arraste sobre o gráfico para ampliar; com Shift, arraste para deslocar."
    }

    /// Strings desta extensão, somadas a `L10n.allStrings`.
    static var anthroStrings: [String] {
        [
            Indicators.weightForAge, Indicators.lengthForAge, Indicators.heightForAge, Indicators.lengthOrHeightForAge,
            Indicators.bmiForAge, Age.label, Age.yearSuffix, Age.monthSuffix,
            Calculator.dateOfBirth, Calculator.approximateDate, Calculator.dateOfVisit, Calculator.sex, Calculator.female,
            Calculator.male, Calculator.weight, Calculator.lengthOrHeight, Calculator.measurement, Calculator.recumbent,
            Calculator.standing, Calculator.oedema, Calculator.no, Calculator.yes, Calculator.bmi, Calculator.results,
            Calculator.zScore, Calculator.percentile, Calculator.showChart, Calculator.child, Calculator.measurements,
            Calculator.kilograms, Calculator.centimeters, Calculator.measurementHint, Calculator.tablesUnavailable,
            Calculator.invalidValue,
            Calculator.outOfRangePrefix, Calculator.rangeSeparator,
            Chart.title, Chart.noData, Chart.xAxis, Chart.outOfRangeSuffix, Chart.weightAxis, Chart.lengthOrHeightAxis,
            Chart.bmiAxis, Chart.median, Chart.standardDeviation, Chart.lengthMarker, Chart.heightMarker,
            Chart.zScoreMode, Chart.percentileMode, Chart.legendZScore, Chart.legendPercentile, Chart.indicator,
            Chart.mode, Chart.multiplePoints, Chart.resetZoom, Chart.copy, Chart.export, Chart.exportPDF, Chart.exportPNG,
            Chart.print, Chart.close, Chart.exportFailed, Chart.zoomHint,
        ] + Chart.percentileLabels
    }
}
