# Tests

## Test Strategy

- **Framework**: swift-testing (`import Testing`, `@Test`, `#expect`, `#require`), Swift 6.1.
- **Full-suite command**: `swift test`
- **Conventions**: testes de cenário em `Tests/AnthroCoreTests/`, um arquivo por capability mais um arquivo de paridade; `@testable import AnthroCore` não é usado, os testes exercitam só a API pública da Interface Under Test. Valores `Decimal` comparados por igualdade exata depois de `ClinicalRounding.round`. Fixtures em `Tests/AnthroCoreTests/Fixtures/` declaradas como recurso do target de teste (`.copy("Fixtures")`). CSV malformados para o teste de lacuna são strings inline no teste.
- **Mutation tool**: manual (aplicar a mutação de "Breaks if", ver o teste falhar, reverter).

## Spec-to-Test Mapping

### Capability: growth-reference-data

#### Scenario: Linha do dia 0 de peso para idade de meninos
- **Test name**: linhaDoDia0DePesoParaIdadeDeMeninos
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: o gerador troca as colunas M e S, ou o loader lê `sex` com 1 = menina.
- **Expected red**: expected LMS(l: 0.3487, m: 3.3464, s: 0.14602), got LMS(l: 0, m: 0, s: 0)

#### Scenario: Último dia dos padrões de IMC de meninas
- **Test name**: ultimoDiaDosPadroesDeImcDeMeninas
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: o gerador corta as planilhas em 1826 dias, como o pacote R `anthro`.
- **Expected red**: expected LMS(l: -0.5684, m: 15.2798, s: 0.09825), got LMS(l: 0, m: 0, s: 0)

#### Scenario: Dia além do fim dos padrões
- **Test name**: diaAlemDoFimDosPadroes
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: `standardsLMS` devolve a última linha disponível em vez de `nil`.
- **Expected red**: expected nil, got LMS(l: 0, m: 0, s: 0)

#### Scenario: Mês 61 de IMC para idade de meninos
- **Test name**: mes61DeImcParaIdadeDeMeninos
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: o índice de meses começa em 61 deslocado de uma linha (lê o mês 60).
- **Expected red**: expected LMS(l: -0.7387, m: 15.2641, s: 0.08390), got LMS(l: 0, m: 0, s: 0)

#### Scenario: Peso para idade além de 121 meses
- **Test name**: pesoParaIdadeAlemDe121Meses
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: o gerador estende o peso de referência até 229 meses copiando a última linha.
- **Expected red**: expected nil, got LMS(l: 0, m: 0, s: 0)

#### Scenario: IMC de meninos aos 61,5 meses
- **Test name**: imcDeMeninosAos61eMeioMeses
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: a interpolação usa `Round(m)` como mês inferior sem a regra de escolha do par, ou não interpola S.
- **Expected red**: expected LMS(l: -0.7504, m: 15.26285, s: 0.08402), got LMS(l: 0, m: 0, s: 0)

#### Scenario: Último intervalo válido de estatura
- **Test name**: ultimoIntervaloValidoDeEstatura
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: o gerador descarta a linha de 229 meses (sem par superior, 228.5 meses viraria `nil`).
- **Expected red**: expected LMS(l: 1, m: 163.1548, s: 0.04009), got LMS(l: 0, m: 0, s: 0)

#### Scenario: Mês superior ausente
- **Test name**: mesSuperiorAusente
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: com o mês superior ausente, a busca devolve a linha inferior sem interpolar.
- **Expected red**: expected nil, got LMS(l: 0, m: 0, s: 0)

#### Scenario: Mês inferior ausente
- **Test name**: mesInferiorAusente
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: com o mês inferior ausente, a busca devolve a linha superior.
- **Expected red**: expected nil, got LMS(l: 0, m: 0, s: 0)

#### Scenario: Recurso embutido completo
- **Test name**: recursoEmbutidoCompleto
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: o recurso não é copiado para o bundle do target, ou uma das seis planilhas não é convertida.
- **Expected red**: expected rowCount 1857 for (.weightForAge, .standards, .boy), got 0

#### Scenario: Recurso com dia faltando
- **Test name**: recursoComDiaFaltando
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: o loader aceita idades não contíguas sem validar.
- **Expected red**: expected thrown ReferenceDataError.gap(indicator: .weightForAge, sex: .boy, age: 100), got no error

#### Scenario: Linha +2 DP no dia 0 de peso de meninos
- **Test name**: linhaMais2DpNoDia0DePesoDeMeninos
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: a fórmula usa $M (1 + L S k)^{L}$ em vez do expoente $1/L$, ou os offsets começam em -2.
- **Expected red**: expected first point x = 0, values[3] = 3.3464, values[5] = 4.4194 (4 casas), got empty series

#### Scenario: Número de pontos e limite superior de peso
- **Test name**: numeroDePontosELimiteSuperiorDePeso
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: a amostragem de padrões passa a ser diária, ou o limite de peso na referência vira 121.
- **Expected red**: expected 526 points with last x = 120, got 0 points

#### Scenario: Percentil 50 igual à mediana
- **Test name**: percentil50IgualAMediana
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: os offsets de percentil usam 1.88 no lugar de 0 para o percentil 50, ou a lista de offsets fica fora de ordem.
- **Expected red**: expected 634 points, each with values[2] == M, got 0 points

#### Scenario: Limite superior das curvas de IMC
- **Test name**: limiteSuperiorDasCurvasDeImc
- **Test file**: Tests/AnthroCoreTests/GrowthReferenceDataTests.swift
- **Level**: acceptance
- **Breaks if**: o filtro `age <= 228` vira `age < 228` ou é removido (série terminaria em 229).
- **Expected red**: expected 634 points with last x = 228, got 0 points

### Capability: anthropometric-computation

#### Scenario: Idade de uma criança de cinco anos
- **Test name**: idadeDeUmaCriancaDeCincoAnos
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o dia é extraído em UTC em vez do calendário do usuário (nascimento às 23h30 locais em fuso a oeste de Greenwich cairia no dia seguinte), ou meses usam 30.4 em vez de 30.4375.
- **Expected red**: expected 1843 days, got 0

#### Scenario: Nascimento depois da visita
- **Test name**: nascimentoDepoisDaVisita
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: `ageInDays` devolve valor negativo em vez de lançar.
- **Expected red**: expected thrown AnthroError.birthAfterVisit, got no error

#### Scenario: Meses fracionados
- **Test name**: mesesFracionadosViramDias
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: `monthsToDays` trunca em vez de arredondar (daria 1871).
- **Expected red**: expected 1872, got 0

#### Scenario: Dois anos exatos
- **Test name**: doisAnosExatosViram731Dias
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: `monthsToDays` usa arredondamento bancário (730.5 viraria 730).
- **Expected red**: expected 731, got 0

#### Scenario: Último dia dos padrões e primeiro da referência
- **Test name**: ultimoDiaDosPadroesEPrimeiroDaReferencia
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: a comparação usa `< 1856` em vez de `<= 1856`.
- **Expected red**: expected .standards for 1856, got .unknown

#### Scenario: Última idade válida e primeira fora dos limites
- **Test name**: ultimaIdadeValidaEPrimeiraForaDosLimites
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o limite compara meses fracionados (`> 228`) em vez da parte inteira, tornando 6970 dias fora dos limites.
- **Expected red**: expected .reference for 6970 days, got .unknown

#### Scenario: Sexo ausente
- **Test name**: sexoAusenteZeraResultados
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: sem sexo, o motor assume menino.
- **Expected red**: expected weightForAge.zScore nil, got 0

#### Scenario: Idade ausente
- **Test name**: idadeAusenteDaFaixaDesconhecida
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: sem idade, o motor usa 0 dias e calcula nos padrões.
- **Expected red**: expected lengthOrHeightForAge.zScore nil, got 0

#### Scenario: Comprimento medido em pé
- **Test name**: comprimentoMedidoEmPeSoma07
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o limiar de comprimento usa 730 em vez de 731, ou o ajuste tem sinal trocado.
- **Expected red**: expected (80.70, isLength: true), got (0, false)

#### Scenario: Altura medida deitada
- **Test name**: alturaMedidaDeitadaSubtrai07
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o ajuste de 0,7 cm é omitido para altura.
- **Expected red**: expected (89.30, isLength: false), got (0, false)

#### Scenario: Referência ignora o modo de medida
- **Test name**: referenciaIgnoraOModoDeMedida
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o motor aplica `adjustedLengthOrHeight` também na faixa de referência (daria 109.30).
- **Expected red**: expected adjustedLengthOrHeight 110.00, got 0

#### Scenario: Peso com três casas
- **Test name**: pesoComTresCasasArredondaAntes
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o motor não arredonda o peso de entrada, ou usa arredondamento bancário (20.00).
- **Expected red**: expected weight 20.01, got 0

#### Scenario: Peso ausente
- **Test name**: pesoAusenteZeraPesoEImc
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: peso ausente vira 0 kg e o IMC é calculado.
- **Expected red**: expected weight nil and bmiForAge.zScore nil, got 0

#### Scenario: IMC de 20 kg e 110 cm
- **Test name**: imcDe20KgE110Cm
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: a medida não é dividida por 100, ou o IMC é arredondado antes de ser exposto.
- **Expected red**: expected 16.5289256198347 (13 casas), got 0

#### Scenario: IMC absurdo
- **Test name**: imcAbsurdoEIndefinido
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o teto de 1000 é removido.
- **Expected red**: expected nil, got 0

#### Scenario: Estatura em +2 DP
- **Test name**: estaturaEmMais2Dp
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: a fórmula LMS divide por `L` em vez de `L * S`.
- **Expected red**: expected 2.00, got 0

#### Scenario: Estatura além de +3 DP não é ajustada
- **Test name**: estaturaAlemDe3DpNaoEAjustada
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o motor limita o z de estatura a 3.00 (clamp) ou o trata como indefinido acima de 3. Com L = 1, como em todas as linhas de estatura da OMS, a fórmula ajustada coincide com a LMS, então o que este teste protege é a ausência de corte, não a escolha da fórmula.
- **Expected red**: expected 4.00, got 0

#### Scenario: Medida inválida
- **Test name**: medidaInvalidaZeraEstatura
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o limite mínimo de 1 cm é removido.
- **Expected red**: expected lengthOrHeightForAge.zScore nil, got 0

#### Scenario: Peso acima de +3 DP
- **Test name**: pesoAcimaDe3DpUsaAjuste
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o ramo `z > 3` é removido (daria 3.92), ou usa $SD3 - SD2$ com sinal trocado.
- **Expected red**: expected 4.00, got 0

#### Scenario: Peso abaixo de -3 DP
- **Test name**: pesoAbaixoDeMenos3DpUsaAjuste
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o ramo `z < -3` usa as distâncias positivas (+2, +3) em vez de -2 e -3 (daria valor diferente de -4.00), ou é removido (daria -4.13).
- **Expected red**: expected -4.00, got 0

#### Scenario: Peso dentro de 3 DP
- **Test name**: pesoNaMedianaDaZeroEPercentil50
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o percentil é arredondado para 0 casas, ou `ZScore.lms` subtrai 1 antes de elevar (o z na mediana deixaria de ser 0). O teste chama `ZScore.lms` e `ZScore.centile` sobre a linha do dia 0, porque pelo motor o peso 3.3464 seria arredondado para 3.35 antes do cálculo, como no original.
- **Expected red**: expected z 0.00 and percentile 50.0, got 0 and 0 (o `ClinicalRounding.round` do stub devolve 0)

#### Scenario: Criança com edema
- **Test name**: criancaComEdemaZeraPesoEImc
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o edema só zera o peso para idade e mantém o IMC.
- **Expected red**: expected bmiForAge.zScore nil, got 0

#### Scenario: Peso abaixo do mínimo
- **Test name**: pesoAbaixoDoMinimoZeraPeso
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o mínimo de 0.9 kg vira `<= 0.9` ou é removido.
- **Expected red**: expected weightForAge.zScore nil, got 0

#### Scenario: Última idade com peso para idade
- **Test name**: ultimaIdadeComPesoParaIdade
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o gerador omite a linha de 121 meses (120.97 meses não teria par superior).
- **Expected red**: expected z 0.16 and percentile 56.4, got 0 and 0

#### Scenario: Primeira idade sem peso para idade
- **Test name**: primeiraIdadeSemPesoParaIdade
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: a busca de referência faz clamp no último mês disponível.
- **Expected red**: expected weightForAge.zScore nil, got 0

#### Scenario: Percentis de z conhecidos
- **Test name**: percentisDeZConhecidos
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o ramo negativo devolve `p` em vez de `100 - p`, ou um coeficiente polinomial muda de sinal.
- **Expected red**: expected [84.1, 2.3, 99.9], got [0, 0, 0]

#### Scenario: Percentil além de 3 DP
- **Test name**: percentilAlemDe3DpEIndefinido
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o corte usa o z arredondado (3.0001 viraria 3.00 e teria percentil).
- **Expected red**: expected nil, got 0

#### Scenario: Empates longe de zero
- **Test name**: empatesArredondamLongeDeZero
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: `round` usa `NSDecimalRound` com `.bankers` (0.125 viraria 0.12).
- **Expected red**: expected [2.35, -2.35, 0.13], got [0, 0, 0]

#### Scenario: Valor indefinido
- **Test name**: valorIndefinidoContinuaIndefinido
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: `round(nil)` devolve 0.
- **Expected red**: expected nil, got 0

#### Scenario: Soma binária imprecisa
- **Test name**: somaBinariaImprecisaViraDecimalExato
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: `decimal15` usa `Decimal(Double)` direto (daria 0.30000000000000004).
- **Expected red**: expected 0.3, got 0

#### Scenario: Valor não finito
- **Test name**: valorNaoFinitoViraNil
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: `decimal15` converte infinito para `Decimal.greatestFiniteMagnitude`.
- **Expected red**: expected nil, got 0

#### Scenario: Limites dos intervalos
- **Test name**: limitesDosIntervalosDePlausibilidade
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o limite superior de peso usa 6 em vez de 5, ou a comparação passa a `>=`.
- **Expected red**: expected isFlagged(.weightForAge, 5.01) == true, got false

#### Scenario: Peso e estatura implausíveis ao mesmo tempo
- **Test name**: pesoEEstaturaImplausiveisAoMesmoTempo
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: a ordem de avaliação testa IMC antes da combinação peso e estatura.
- **Expected red**: expected .weightAndLengthOrHeightForAge, got .none

#### Scenario: Fronteiras das faixas
- **Test name**: fronteirasDasFaixasDeGravidade
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: as comparações usam `<=` (1.00 viraria `.normal`).
- **Expected red**: expected [.normal, .moderate, .high, .extreme], got [.undefined, .undefined, .undefined, .undefined]

#### Scenario: Negativo extremo e indefinido
- **Test name**: negativoExtremoEIndefinido
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: a classificação usa `z` em vez de `abs(z)` (−3.50 viraria `.normal`).
- **Expected red**: expected [.extreme, .undefined], got [.undefined, .undefined]

#### Scenario: Peso para idade aos 121 meses informados
- **Test name**: pesoParaIdadeAos121MesesInformados
- **Test file**: Tests/AnthroCoreTests/AnthropometricComputationTests.swift
- **Level**: acceptance
- **Breaks if**: o motor recalcula meses a partir de `monthsToDays(121)` = 3683 dias (121.002 meses, sem linha superior) em vez de usar os meses informados.
- **Expected red**: expected z 2.00 and percentile 97.7, got 0 and 0

#### Scenario: Fixture de padrões
- **Test name**: fixtureDePadroesBateComAnthro
- **Test file**: Tests/AnthroCoreTests/GoldenParityTests.swift
- **Level**: acceptance
- **Breaks if**: o ajuste de 0,7 cm usa o limiar errado, ou o IMC é calculado com a medida não ajustada.
- **Expected red**: expected max diff $\leq$ 0.01 and $\geq$ 594 exact matches, got 0 exact matches (stub devolve z = 0)

#### Scenario: Fixture de referência
- **Test name**: fixtureDeReferenciaBateComAnthroplus
- **Test file**: Tests/AnthroCoreTests/GoldenParityTests.swift
- **Level**: acceptance
- **Breaks if**: a interpolação de meses fracionados é removida (usa só o mês inferior).
- **Expected red**: expected max diff $\leq$ 0.01 and $\geq$ 594 exact matches, got 0 exact matches (stub devolve z = 0)

## Coverage Ledger

| Capability | Scenario | Test file | Test name | Breaks if | Red (SHA: failure) | Green (SHA) | State |
|------------|----------|-----------|-----------|-----------|--------------------|-------------|-------|
| growth-reference-data | Linha do dia 0 de peso para idade de meninos | GrowthReferenceDataTests.swift | linhaDoDia0DePesoParaIdadeDeMeninos | colunas M/S trocadas | 0da1e12: `GrowthReferenceDataTests.swift:16 Expectation failed: (tables.standardsLMS(.weightForAge, sex: .boy, ageInDays: 0) -> LMS(l: 0, m: 0, s: 0)) ...` | 0d42b8d | green |
| growth-reference-data | Último dia dos padrões de IMC de meninas | GrowthReferenceDataTests.swift | ultimoDiaDosPadroesDeImcDeMeninas | corte em 1826 | 0da1e12: `GrowthReferenceDataTests.swift:21 Expectation failed: (tables.standardsLMS(.bmiForAge, sex: .girl, ageInDays: 1856) -> LMS(l: 0, m: 0, s: 0))...` | 0d42b8d | green |
| growth-reference-data | Dia além do fim dos padrões | GrowthReferenceDataTests.swift | diaAlemDoFimDosPadroes | devolve última linha | 0da1e12: `GrowthReferenceDataTests.swift:26 Expectation failed: (tables.standardsLMS(.weightForAge, sex: .boy, ageInDays: 1857) -> LMS(l: 0, m: 0, s: 0...` | 0d42b8d | green |
| growth-reference-data | Mês 61 de IMC para idade de meninos | GrowthReferenceDataTests.swift | mes61DeImcParaIdadeDeMeninos | índice deslocado | 0da1e12: `GrowthReferenceDataTests.swift:31 Expectation failed: (tables.referenceLMS(.bmiForAge, sex: .boy, ageInMonths: 61) -> LMS(l: 0, m: 0, s: 0)) ...` | 0d42b8d | green |
| growth-reference-data | Peso para idade além de 121 meses | GrowthReferenceDataTests.swift | pesoParaIdadeAlemDe121Meses | peso estendido a 229 | 0da1e12: `GrowthReferenceDataTests.swift:36 Expectation failed: (tables.referenceLMS(.weightForAge, sex: .boy, ageInMonths: 122) -> LMS(l: 0, m: 0, s: ...` | 0d42b8d | green |
| growth-reference-data | IMC de meninos aos 61,5 meses | GrowthReferenceDataTests.swift | imcDeMeninosAos61eMeioMeses | sem interpolação | 0da1e12: `GrowthReferenceDataTests.swift:41 Expectation failed: (tables.referenceLMS(.bmiForAge, sex: .boy, ageInMonths: d("61.5")) -> LMS(l: 0, m: 0, ...` | 62b59f8 | green |
| growth-reference-data | Último intervalo válido de estatura | GrowthReferenceDataTests.swift | ultimoIntervaloValidoDeEstatura | linha 229 descartada | 0da1e12: `GrowthReferenceDataTests.swift:46 Expectation failed: (tables.referenceLMS(.lengthOrHeightForAge, sex: .girl, ageInMonths: d("228.5")) -> LMS...` | 62b59f8 | green |
| growth-reference-data | Mês superior ausente | GrowthReferenceDataTests.swift | mesSuperiorAusente | devolve linha inferior | 0da1e12: `GrowthReferenceDataTests.swift:51 Expectation failed: (tables.referenceLMS(.bmiForAge, sex: .boy, ageInMonths: d("229.5")) -> LMS(l: 0, m: 0,...` | 62b59f8 | green |
| growth-reference-data | Mês inferior ausente | GrowthReferenceDataTests.swift | mesInferiorAusente | devolve linha superior | 0da1e12: `GrowthReferenceDataTests.swift:56 Expectation failed: (tables.referenceLMS(.bmiForAge, sex: .boy, ageInMonths: d("59.5")) -> LMS(l: 0, m: 0, ...` | 62b59f8 | green |
| growth-reference-data | Recurso embutido completo | GrowthReferenceDataTests.swift | recursoEmbutidoCompleto | recurso fora do bundle | 0da1e12: `GrowthReferenceDataTests.swift:63 Expectation failed: (tables.rowCount(indicator, range: .standards, sex: sex) -> 0) == 1857` | 0d42b8d | green |
| growth-reference-data | Recurso com dia faltando | GrowthReferenceDataTests.swift | recursoComDiaFaltando | sem validação de lacuna | 0da1e12: `GrowthReferenceDataTests.swift:90 Expectation failed: an error was expected but none was thrown and "GrowthReferenceTables()" was returned` | 0d42b8d | green |
| growth-reference-data | Linha +2 DP no dia 0 de peso de meninos | GrowthReferenceDataTests.swift | linhaMais2DpNoDia0DePesoDeMeninos | expoente L em vez de 1/L | 0da1e12: `GrowthReferenceDataTests.swift:97 Expectation failed: (GrowthCurves.zScoreOffsets -> []) == [-3, -2, -1, 0, 1, 2, 3]` | 3d6703e | green |
| growth-reference-data | Número de pontos e limite superior de peso | GrowthReferenceDataTests.swift | numeroDePontosELimiteSuperiorDePeso | amostragem diária | 0da1e12: `GrowthReferenceDataTests.swift:109 Expectation failed: (points.count -> 0) == 526` | 3d6703e | green |
| growth-reference-data | Percentil 50 igual à mediana | GrowthReferenceDataTests.swift | percentil50IgualAMediana | offset errado no P50 | 0da1e12: `GrowthReferenceDataTests.swift:115 Expectation failed: (GrowthCurves.percentileOffsets -> []) == ([d("-1.88"), d("-1.036"), 0, d("1.036"), d("...` | 3d6703e | green |
| growth-reference-data | Limite superior das curvas de IMC | GrowthReferenceDataTests.swift | limiteSuperiorDasCurvasDeImc | filtro de 228 removido | 0da1e12: `GrowthReferenceDataTests.swift:130 Expectation failed: (points.count -> 0) == 634` | 3d6703e | green |
| anthropometric-computation | Idade de uma criança de cinco anos | AnthropometricComputationTests.swift | idadeDeUmaCriancaDeCincoAnos | fuso local | 0da1e12: `AnthropometricComputationTests.swift:30 Expectation failed: (days -> 0) == 1843` | 4f829fb | green |
| anthropometric-computation | Nascimento depois da visita | AnthropometricComputationTests.swift | nascimentoDepoisDaVisita | idade negativa sem erro | 0da1e12: `AnthropometricComputationTests.swift:36 Expectation failed: an error was expected but none was thrown and "0" was returned` | 4f829fb | green |
| anthropometric-computation | Meses fracionados | AnthropometricComputationTests.swift | mesesFracionadosViramDias | truncamento | 0da1e12: `AnthropometricComputationTests.swift:45 Expectation failed: (AgeMath.monthsToDays(d("61.5")) -> 0) == 1872` | 4f829fb | green |
| anthropometric-computation | Dois anos exatos | AnthropometricComputationTests.swift | doisAnosExatosViram731Dias | arredondamento bancário | 0da1e12: `AnthropometricComputationTests.swift:50 Expectation failed: (AgeMath.monthsToDays(24) -> 0) == 731` | 4f829fb | green |
| anthropometric-computation | Último dia dos padrões e primeiro da referência | AnthropometricComputationTests.swift | ultimoDiaDosPadroesEPrimeiroDaReferencia | `<` no lugar de `<=` | 0da1e12: `AnthropometricComputationTests.swift:57 Expectation failed: (AgeMath.ageRange(days: 1856, months: AgeMath.daysToMonths(1856)) -> .unknown) == .stan...` | dfea316 | green |
| anthropometric-computation | Última idade válida e primeira fora dos limites | AnthropometricComputationTests.swift | ultimaIdadeValidaEPrimeiraForaDosLimites | meses fracionados no limite | 0da1e12: `AnthropometricComputationTests.swift:65 Expectation failed: (engine.at(days: 6970, sex: .boy, weight: 60, height: 170).ageRange -> .unknown) == .re...` | dfea316 | green |
| anthropometric-computation | Sexo ausente | AnthropometricComputationTests.swift | sexoAusenteZeraResultados | assume menino | 0da1e12: `AnthropometricComputationTests.swift:79 Expectation failed: (result.score(indicator) -> IndicatorScore(zScore: Optional(0), percentile: Optional(0)...` | dfea316 | green |
| anthropometric-computation | Idade ausente | AnthropometricComputationTests.swift | idadeAusenteDaFaixaDesconhecida | assume 0 dias | 0da1e12: `AnthropometricComputationTests.swift:88 Expectation failed: (result.score(indicator).zScore -> 0) == nil` | dfea316 | green |
| anthropometric-computation | Comprimento medido em pé | AnthropometricComputationTests.swift | comprimentoMedidoEmPeSoma07 | limiar 730 | 0da1e12: `AnthropometricComputationTests.swift:97 Expectation failed: (adjusted.value -> 0) == (d("80.70") -> 80.7)` | 2ed4c3a | green |
| anthropometric-computation | Altura medida deitada | AnthropometricComputationTests.swift | alturaMedidaDeitadaSubtrai07 | ajuste omitido | 0da1e12: `AnthropometricComputationTests.swift:104 Expectation failed: (adjusted.value -> 0) == (d("89.30") -> 89.3)` | 2ed4c3a | green |
| anthropometric-computation | Referência ignora o modo de medida | AnthropometricComputationTests.swift | referenciaIgnoraOModoDeMedida | ajuste na referência | 0da1e12: `AnthropometricComputationTests.swift:111 Expectation failed: (result.adjustedLengthOrHeight -> 0) == (d("110.00") -> 110)` | dfea316 | green |
| anthropometric-computation | Peso com três casas | AnthropometricComputationTests.swift | pesoComTresCasasArredondaAntes | sem arredondar entrada | 0da1e12: `AnthropometricComputationTests.swift:118 Expectation failed: (engine.at(days: 2000, sex: .girl, weight: d("20.005"), height: 110).weight -> 0) == (d...` | dfea316 | green |
| anthropometric-computation | Peso ausente | AnthropometricComputationTests.swift | pesoAusenteZeraPesoEImc | peso nulo vira 0 | 0da1e12: `AnthropometricComputationTests.swift:124 Expectation failed: (result.weight -> 0) == nil` | dfea316 | green |
| anthropometric-computation | IMC de 20 kg e 110 cm | AnthropometricComputationTests.swift | imcDe20KgE110Cm | cm sem dividir por 100 | 0da1e12: `AnthropometricComputationTests.swift:134 Expectation failed: (r(bmi, 13) -> 0) == (d("16.5289256198347") -> 16.5289256198347)` | 2ed4c3a | green |
| anthropometric-computation | IMC absurdo | AnthropometricComputationTests.swift | imcAbsurdoEIndefinido | teto removido | 0da1e12: `AnthropometricComputationTests.swift:140 Expectation failed: (Anthropometry.exactBMI(weight: 275, lengthOrHeight: 1) -> 0) == nil` | 2ed4c3a | green |
| anthropometric-computation | Estatura em +2 DP | AnthropometricComputationTests.swift | estaturaEmMais2Dp | divide por L | 0da1e12: `AnthropometricComputationTests.swift:148 Expectation failed: (result.lengthOrHeightForAge.zScore -> 0) == (d("2.00") -> 2)` | dfea316 | green |
| anthropometric-computation | Estatura além de +3 DP não é ajustada | AnthropometricComputationTests.swift | estaturaAlemDe3DpNaoEAjustada | clamp em 3.00 | 0da1e12: `AnthropometricComputationTests.swift:154 Expectation failed: (result.lengthOrHeightForAge.zScore -> 0) == (d("4.00") -> 4)` | dfea316 | green |
| anthropometric-computation | Medida inválida | AnthropometricComputationTests.swift | medidaInvalidaZeraEstatura | mínimo removido | 0da1e12: `AnthropometricComputationTests.swift:160 Expectation failed: (result.lengthOrHeightForAge -> IndicatorScore(zScore: Optional(0), percentile: Optiona...` | dfea316 | green |
| anthropometric-computation | Peso acima de +3 DP | AnthropometricComputationTests.swift | pesoAcimaDe3DpUsaAjuste | ramo z > 3 removido | 0da1e12: `AnthropometricComputationTests.swift:167 Expectation failed: (r(ZScore.lms(d("5.641924702067"), weightBoyDay0, restricted: true), 2) -> 0) == (d("4....` | aec643a | green |
| anthropometric-computation | Peso abaixo de -3 DP | AnthropometricComputationTests.swift | pesoAbaixoDeMenos3DpUsaAjuste | ramo z < -3 errado | 0da1e12: `AnthropometricComputationTests.swift:172 Expectation failed: (r(ZScore.lms(d("1.701303187307"), weightBoyDay0, restricted: true), 2) -> 0) == (d("-4...` | aec643a | green |
| anthropometric-computation | Peso dentro de 3 DP | AnthropometricComputationTests.swift | pesoNaMedianaDaZeroEPercentil50 | percentil sem casa | 0da1e12: `AnthropometricComputationTests.swift:179 Expectation failed: (r(ZScore.centile(z), 1) -> 0) == (d("50.0") -> 50)` | aec643a | green |
| anthropometric-computation | Criança com edema | AnthropometricComputationTests.swift | criancaComEdemaZeraPesoEImc | IMC mantido com edema | 0da1e12: `AnthropometricComputationTests.swift:187 Expectation failed: (result.weightForAge.zScore -> 0) == nil` | dfea316 | green |
| anthropometric-computation | Peso abaixo do mínimo | AnthropometricComputationTests.swift | pesoAbaixoDoMinimoZeraPeso | mínimo removido | 0da1e12: `AnthropometricComputationTests.swift:194 Expectation failed: (engine.at(days: 0, sex: .boy, weight: d("0.85"), height: nil).weightForAge.zScore -> 0...` | dfea316 | green |
| anthropometric-computation | Última idade com peso para idade | AnthropometricComputationTests.swift | ultimaIdadeComPesoParaIdade | linha 121 omitida | 0da1e12: `AnthropometricComputationTests.swift:202 Expectation failed: (result.weightForAge -> IndicatorScore(zScore: Optional(0), percentile: Optional(0))) =...` | dfea316 | green |
| anthropometric-computation | Primeira idade sem peso para idade | AnthropometricComputationTests.swift | primeiraIdadeSemPesoParaIdade | clamp no último mês | 0da1e12: `AnthropometricComputationTests.swift:208 Expectation failed: (result.weightForAge.zScore -> 0) == nil` | dfea316 | green |
| anthropometric-computation | Percentis de z conhecidos | AnthropometricComputationTests.swift | percentisDeZConhecidos | ramo negativo errado | 0da1e12: `AnthropometricComputationTests.swift:217 Expectation failed: (r(ZScore.centile(1), 1) -> 0) == (d("84.1") -> 84.1)` | aec643a | green |
| anthropometric-computation | Percentil além de 3 DP | AnthropometricComputationTests.swift | percentilAlemDe3DpEIndefinido | corte sobre z arredondado | 0da1e12: `AnthropometricComputationTests.swift:224 Expectation failed: (ZScore.centile(d("3.0001")) -> 0) == nil` | aec643a | green |
| anthropometric-computation | Empates longe de zero | AnthropometricComputationTests.swift | empatesArredondamLongeDeZero | arredondamento bancário | 0da1e12: `AnthropometricComputationTests.swift:232 Expectation failed: (r(d("2.345"), 2) -> 0) == (d("2.35") -> 2.35)` | dbab0da | green |
| anthropometric-computation | Valor indefinido | AnthropometricComputationTests.swift | valorIndefinidoContinuaIndefinido | nil vira 0 | 0da1e12: `AnthropometricComputationTests.swift:239 Expectation failed: (r(nil, 2) -> 0) == nil` | dbab0da | green |
| anthropometric-computation | Soma binária imprecisa | AnthropometricComputationTests.swift | somaBinariaImprecisaViraDecimalExato | Decimal(Double) direto | 0da1e12: `AnthropometricComputationTests.swift:246 Expectation failed: (ClinicalRounding.decimal15(0.1 + 0.2) -> 0) == (d("0.3") -> 0.3)` | dbab0da | green |
| anthropometric-computation | Valor não finito | AnthropometricComputationTests.swift | valorNaoFinitoViraNil | infinito vira máximo | 0da1e12: `AnthropometricComputationTests.swift:251 Expectation failed: (ClinicalRounding.decimal15(.infinity) -> 0) == nil` | dbab0da | green |
| anthropometric-computation | Limites dos intervalos | AnthropometricComputationTests.swift | limitesDosIntervalosDePlausibilidade | limite de peso 6 | 0da1e12: `AnthropometricComputationTests.swift:259 Expectation failed: (Plausibility.isFlagged(.weightForAge, z: d("5.01")) -> false) == true` | 532c740 | green |
| anthropometric-computation | Peso e estatura implausíveis ao mesmo tempo | AnthropometricComputationTests.swift | pesoEEstaturaImplausiveisAoMesmoTempo | ordem trocada | 0da1e12: `AnthropometricComputationTests.swift:275 Expectation failed: (Plausibility.flag(for: result) -> .none) == .weightAndLengthOrHeightForAge` | 532c740 | green |
| anthropometric-computation | Fronteiras das faixas | AnthropometricComputationTests.swift | fronteirasDasFaixasDeGravidade | `<=` nas fronteiras | 0da1e12: `AnthropometricComputationTests.swift:282 Expectation failed: (SeverityClassifier.severity(d("0.99")) -> .undefined) == .normal` | 532c740 | green |
| anthropometric-computation | Negativo extremo e indefinido | AnthropometricComputationTests.swift | negativoExtremoEIndefinido | sem valor absoluto | 0da1e12: `AnthropometricComputationTests.swift:290 Expectation failed: (SeverityClassifier.severity(d("-3.50")) -> .undefined) == .extreme` | 532c740 | green |
| anthropometric-computation | Peso para idade aos 121 meses informados | AnthropometricComputationTests.swift | pesoParaIdadeAos121MesesInformados | meses recalculados dos dias | 0da1e12: `AnthropometricComputationTests.swift:299 Expectation failed: (result.weightForAge -> IndicatorScore(zScore: Optional(0), percentile: Optional(0))) =...` | dfea316 | green |
| anthropometric-computation | Fixture de padrões | GoldenParityTests.swift | fixtureDePadroesBateComAnthro | limiar de 0,7 cm errado | 0da1e12: `GoldenParityTests.swift:93 Expectation failed: (comparison.maxDifference -> 99) <= (d("0.01") -> 0.01)` | ecbf18d | green |
| anthropometric-computation | Fixture de referência | GoldenParityTests.swift | fixtureDeReferenciaBateComAnthroplus | sem interpolação | 0da1e12: `GoldenParityTests.swift:102 Expectation failed: (comparison.maxDifference -> 99) <= (d("0.01") -> 0.01)` | ecbf18d | green |

## Test Changes After Red

- **2026-10-14, `fixtureDePadroesBateComAnthro` (dados da fixture, não as asserções).** Na primeira execução verde, 44 de 600 casos divergiam do R só em estatura e IMC, por exatamente o efeito de 0,7 cm. Causa raiz: `anthro_zscores` (pacote `anthro` 1.1.0) marca medida em pé abaixo de 9 meses como implausível (`c9mo_flag`), descarta o tipo de medida e não aplica o ajuste; o AnthroPlus 1.0.4 aplica (`AnthroComputation.GetAdjustedLengthOrHeight`). Os 44 casos eram exatamente os sorteios em pé abaixo de 9 meses. Mudança: `scripts/golden/generate_golden.R` passou a excluir esses sorteios (registrado no cabeçalho, como a exclusão de 121,0 meses), e `golden-standards.csv` foi regenerado. Spec emendada: o cenário "Fixture de padrões" declara a exclusão. Asserções do teste inalteradas. Resultado: 600 de 600 casos idênticos, diferença máxima 0. OK do usuário: informado no relatório da change; o motor não mudou.
