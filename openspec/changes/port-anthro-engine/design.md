# Design

## Context

O cálculo do WHO AnthroPlus está em `reference/decompiled/bll/WHOAnthroPlus.BLL.Core/AnthroComputation.cs` (BLL) e `reference/decompiled/dal/WHOAnthroPlus.DAL.Reference/AnthroReferenceData.cs` (DAL). O original usa `decimal` do .NET para valores e `Math.Pow`/`Math.Exp` em `double`, convertendo de volta com cast explícito, que arredonda para 15 dígitos significativos. As tabelas LMS ficam no `.sdf` cifrado (`AnthroStd_*` por dia, `AnthroRef_*` por mês); usamos as tabelas públicas da OMS em `reference/who-tables/` (ver `docs/reverse-engineering-findings.md`, seção "Dados de referência"). Com `EnableRefDataCaching = True` (padrão do `.exe.config`), o original carrega todas as tabelas em memória e usa o caminho de cache de `Get4AgeIndicatorDataPoint`; esse é o caminho portado.

## Goals / Non-Goals

**Goals:**
- Port fiel, função por função, de `AnthroComputation` e da parte de leitura de `AnthroReferenceData`.
- Tabelas embutidas no bundle, carregadas uma vez, validadas na carga.
- Séries de curvas idênticas às consultas SQL de `GetIndicatorDataCurves`.
- Paridade medida contra os pacotes R da OMS.

**Non-Goals:**
- Interface gráfica, persistência, importação (changes 3 a 9).
- Indicadores que o AnthroPlus não calcula (peso para estatura, perímetro cefálico, dobras).
- Ler o `.sdf` original.

## Interface Under Test

| Entry point | Signature | File |
|-------------|-----------|------|
| Sexo | `public enum Sex: Int, Sendable, Codable, CaseIterable { case girl = 0, boy = 1 }` | `Sources/AnthroCore/Model.swift` |
| Indicador | `public enum Indicator: Int, Sendable, CaseIterable { case weightForAge = 0, lengthOrHeightForAge = 1, bmiForAge = 2 }` | `Sources/AnthroCore/Model.swift` |
| Faixa | `public enum AgeRange: Sendable { case unknown, standards, reference, offLimits }` | `Sources/AnthroCore/Model.swift` |
| LMS | `public struct LMS: Sendable, Equatable { public let l: Decimal; public let m: Decimal; public let s: Decimal }` | `Sources/AnthroCore/Model.swift` |
| Escore | `public struct IndicatorScore: Sendable, Equatable { public let zScore: Decimal?; public let percentile: Decimal? }` | `Sources/AnthroCore/Model.swift` |
| Resultado | `public struct AnthropometricResult: Sendable, Equatable { public let sex: Sex?; public let ageInDays: Int?; public let ageInMonths: Decimal?; public let ageRange: AgeRange; public let weight: Decimal?; public let lengthOrHeight: Decimal?; public let adjustedLengthOrHeight: Decimal?; public let isLength: Bool; public let weightForAge: IndicatorScore; public let lengthOrHeightForAge: IndicatorScore; public let bmiForAge: IndicatorScore; public func score(_ indicator: Indicator) -> IndicatorScore }` | `Sources/AnthroCore/Model.swift` |
| Erros | `public enum AnthroError: Error, Equatable { case birthAfterVisit }` e `public enum ReferenceDataError: Error, Equatable { case missingResource(String); case malformedRow(file: String, line: Int); case gap(indicator: Indicator, sex: Sex, age: Int) }` | `Sources/AnthroCore/Errors.swift` |
| Tabelas | `public struct GrowthReferenceTables: Sendable { public static func bundled() throws -> GrowthReferenceTables; public static func load(standardsCSV: [Indicator: String], referenceCSV: [Indicator: String]) throws -> GrowthReferenceTables; public func standardsLMS(_ indicator: Indicator, sex: Sex, ageInDays: Int) -> LMS?; public func referenceLMS(_ indicator: Indicator, sex: Sex, ageInMonths: Decimal) -> LMS?; public func rowCount(_ indicator: Indicator, range: AgeRange, sex: Sex) -> Int }` | `Sources/AnthroCore/GrowthReferenceTables.swift` |
| Curvas | `public struct CurvePoint: Sendable, Equatable { public let xMonths: Double; public let values: [Double] }` e `public enum CurveKind: Sendable { case zScore, percentile }` e `public enum GrowthCurves { public static func points(_ indicator: Indicator, sex: Sex, kind: CurveKind, tables: GrowthReferenceTables) -> [CurvePoint]; public static let zScoreOffsets: [Decimal]; public static let percentileOffsets: [Decimal] }` | `Sources/AnthroCore/GrowthCurves.swift` |
| Idade | `public enum AgeMath { public static func ageInDays(birth: Date, visit: Date) throws -> Int; public static func daysToMonths(_ days: Int) -> Decimal; public static func monthsToDays(_ months: Decimal) -> Int; public static func ageRange(days: Int, months: Decimal) -> AgeRange }` | `Sources/AnthroCore/AgeMath.swift` |
| Medida | `public enum Anthropometry { public static func adjustedLengthOrHeight(ageInDays: Int, value: Decimal, measuredRecumbent: Bool) -> (value: Decimal, isLength: Bool); public static func exactBMI(weight: Decimal, lengthOrHeight: Decimal) -> Decimal? }` | `Sources/AnthroCore/Anthropometry.swift` |
| Z e percentil | `public enum ZScore { public static func lms(_ y: Decimal, _ lms: LMS, restricted: Bool) -> Decimal?; public static func centile(_ z: Decimal) -> Decimal? }` | `Sources/AnthroCore/ZScore.swift` |
| Numérico | `public enum ClinicalRounding { public static func round(_ x: Decimal?, places: Int) -> Decimal?; public static func decimal15(_ x: Double) -> Decimal? }` | `Sources/AnthroCore/ClinicalRounding.swift` |
| Plausibilidade | `public enum PlausibilityFlag: Sendable { case none, weightForAge, lengthOrHeightForAge, weightAndLengthOrHeightForAge, bmiForAge }` e `public enum Plausibility { public static func isFlagged(_ indicator: Indicator, z: Decimal?) -> Bool; public static func flag(for result: AnthropometricResult) -> PlausibilityFlag }` | `Sources/AnthroCore/Plausibility.swift` |
| Gravidade | `public enum Severity: Sendable { case normal, moderate, high, extreme, undefined }` e `public enum SeverityClassifier { public static func severity(_ z: Decimal?) -> Severity }` | `Sources/AnthroCore/Severity.swift` |
| Limites de entrada | `public enum InputLimits { public static let minWeight: Decimal = 0.9; public static let maxWeight: Decimal = 275; public static let minLengthOrHeight: Decimal = 38; public static let maxLengthOrHeight: Decimal = 230 }` | `Sources/AnthroCore/InputLimits.swift` |
| Motor | `public struct AnthroEngine: Sendable { public init(tables: GrowthReferenceTables); public static func shared() throws -> AnthroEngine; public func result(ageInDays: Int?, ageInMonths: Decimal?, sex: Sex?, weight: Decimal?, lengthOrHeight: Decimal?, measuredRecumbent: Bool, hasOedema: Bool) -> AnthropometricResult; public func result(dateOfBirth: Date?, dateOfVisit: Date?, sex: Sex?, weight: Decimal?, lengthOrHeight: Decimal?, measuredRecumbent: Bool, hasOedema: Bool) throws -> AnthropometricResult }` | `Sources/AnthroCore/AnthroEngine.swift` |

`InputLimits` replica os mínimos e máximos dos `NumericUpDown` (`ACMain`: 0.9 a 275 kg, 38 a 230 cm) e é consumido pelas telas das changes seguintes; o motor não rejeita valores fora desses limites, como o original.

## Decisions

**D1. `Decimal` com conversões de 15 dígitos, em vez de só `Double`.** Cada `(decimal)Math.Pow(...)`, `(decimal)Math.Exp(...)` e `(decimal)Math.Sqrt(...)` do C# vira `ClinicalRounding.decimal15(pow(Double(x), Double(y)))`, implementado como `Decimal(string: String(format: "%.15g", x))`. Alternativa descartada: `Double` em todo o cálculo, que difere do original em empates de arredondamento (ex. z = x.xx5). Valor não finito, que no .NET lança `OverflowException` capturada por `CalculateZandP`, devolve `nil` para o indicador inteiro (z e percentil).

**D2. `nil` no lugar de `decimal.MinValue`.** O original usa `decimal.MinValue` como sentinela de indefinido e `SetExtreme()` para linha ausente; o Swift usa `Optional`. Linha LMS ausente devolve `nil` direto, sem reproduzir a aritmética com `MinValue` que só serve para acabar em exceção.

**D3. Caminho de cache do original.** Porta a semântica de `Get4AgeIndicatorDataPoint` com `_useReferenceTablesCache = true`: padrões por dia exato, referência por mês inteiro ou interpolação entre `Round(m)` e o vizinho, com a mesma regra de escolha do par (`num > m ? (num - 1, num) : (num, num + 1)`). O caminho sem cache do original lança exceção para IMC (usa índice 3 para o indicador 2), por isso não é portado.

**D4. Recurso CSV gerado, versionado no repositório.** `scripts/generate_who_tables.py` (executado com `uv run --with openpyxl`) lê as seis planilhas expandidas e os três CSV do pacote R e escreve `Sources/AnthroCore/Resources/who/{std,ref}-{wfa,lhfa,bfa}.csv` com colunas `sex,age,l,m,s` (sex 1 = menino, 2 = menina, como a OMS), valores copiados como texto, sem reformatar. O script também confere que os dias 0 a 1826 das planilhas coincidem com as tabelas do pacote R `anthro` e falha se não coincidirem. O recurso entra no target com `resources: [.copy("Resources/who")]` (já declarado pela change 1) e é lido por `AnthroCoreResources.bundle`, nunca por `Bundle.module` direto, porque o acessor do SwiftPM não encontra o bundle dentro do `.app` montado à mão (ver risco correspondente no design da change 1). Alternativa descartada: ler as planilhas em tempo de execução, o que exigiria parser de xlsx no app.

**D5. Curvas em `Double`.** Gráficos não precisam de `Decimal`; as séries usam `Double`, como `GetStdOrRefCurvePointArrays` (`Convert.ToDouble`). Padrões com `age % 4 == 0`, x = dias / 30.4375; referência com `age <= 120` (peso) ou `age <= 228` (estatura, IMC), x = meses. A sobreposição entre 60 e 61 meses do original é preservada.

**D6. Fixtures douradas geradas por R.** `scripts/golden/generate_golden.R` instala `anthro` e `anthroplus` 1.1.0 em `.rlib/` (ignorado pelo git), sorteia com semente fixa 600 casos de padrões (idade 0 a 1826 dias, sexo, peso e medida a partir de z sorteado entre -5 e 5 sobre a linha LMS, medida deitada ou em pé, 5% com edema) e 600 de referência (61 a 228 meses, com 30% de meses fracionados), mais uma grade de bordas (730/731, 1826, 61.0, 120.99, 228.99), e grava `Tests/AnthroCoreTests/Fixtures/golden-standards.csv` e `golden-reference.csv` com as entradas e os z arredondados pelo R. O cabeçalho registra versão dos pacotes, semente e casos excluídos (peso para idade em exatamente 121.0 meses, onde o R usa limite exclusivo e o original inclusivo). Observado no CSV do R: a linha de 121 meses de peso repete a de 120 (L, M e S iguais), o que indica linha de preenchimento para a interpolação até 121; o mesmo vale para 229 em estatura e IMC, a conferir pelo gerador.

**D9. Stubs do portão vermelho.** Para que todo teste de cenário falhe por asserção contra os stubs, funções com retorno opcional devolvem valor neutro não nulo (`0`, `LMS(l: 0, m: 0, s: 0)`, resultado com todos os escores `IndicatorScore(zScore: 0, percentile: 0)` e faixa `.unknown`), coleções devolvem vazio, `Bool` devolve `false`, enums devolvem `Severity.undefined`, `PlausibilityFlag.none` e `AgeRange.unknown`, funções `throws` não lançam. Testes de "todos os pontos" também conferem a contagem, para não passarem vazios.

**D7. Percentil com os coeficientes truncados.** `ZScore.centile` replica literalmente `AnthroComputation.Centile`, inclusive 0.31938 e 1.82125 (os valores de Abramowitz e Stegun são 0.319381530 e 1.821255978). A diferença é menor que $10^{-5}$ pontos percentuais, mas a fidelidade é o objetivo.

**D8. Data sem hora.** `AgeMath.ageInDays` extrai ano, mês e dia de cada `Date` no calendário do usuário (`Calendar.current`, o dia que a tela mostra), monta as duas datas à meia-noite UTC e conta os dias entre elas com `Calendar(identifier: .gregorian)` em UTC. Extrair o dia direto em UTC deslocaria um dia as datas escolhidas à noite em São Paulo (UTC-3); contar em fuso local deixaria o horário de verão encurtar um dia. O original usa `DateTime.Date` (dia local) e `TotalDays`.

## Risks / Trade-offs

- [Tabelas públicas diferentes das do `.sdf`] -> Paridade com o R cobre a maior parte do domínio; a confirmação final exige rodar o original em Windows. Registrado como desconhecido em `docs/reverse-engineering-findings.md`.
- [R e original divergem em empates de arredondamento] -> Tolerância de 0.01 com exigência de 99% de igualdade exata; cada divergência é listada pelo teste.
- [Dias 1827 a 1856 sem oráculo R] -> Cobertos por cenários analíticos (z = 0 na mediana, $\pm 2$ e $\pm 4$ construídos) sobre linhas das planilhas.
- [Precisão de `Decimal` do Swift (38 dígitos) maior que a do .NET (28 a 29)] -> Diferenças só aparecem além da 25ª casa, irrelevantes para 2 casas exibidas.

## Open Questions

- Nenhuma que mude o que será construído.
