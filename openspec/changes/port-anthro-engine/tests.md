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
- **Breaks if**: o gerador descarta a linha de 229 meses.
- **Expected red**: expected M strictly between M(228) and M(229), got M = 0

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
- **Breaks if**: a diferença de datas usa o fuso local e perde um dia, ou meses usam 30.4 em vez de 30.4375.
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
- **Breaks if**: o percentil é arredondado para 0 casas, ou o z de peso não usa a linha do dia 0.
- **Expected red**: expected z 0.00 and percentile 50.0, got percentile 0

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
| growth-reference-data | Linha do dia 0 de peso para idade de meninos | GrowthReferenceDataTests.swift | linhaDoDia0DePesoParaIdadeDeMeninos | colunas M/S trocadas | | | planned |
| growth-reference-data | Último dia dos padrões de IMC de meninas | GrowthReferenceDataTests.swift | ultimoDiaDosPadroesDeImcDeMeninas | corte em 1826 | | | planned |
| growth-reference-data | Dia além do fim dos padrões | GrowthReferenceDataTests.swift | diaAlemDoFimDosPadroes | devolve última linha | | | planned |
| growth-reference-data | Mês 61 de IMC para idade de meninos | GrowthReferenceDataTests.swift | mes61DeImcParaIdadeDeMeninos | índice deslocado | | | planned |
| growth-reference-data | Peso para idade além de 121 meses | GrowthReferenceDataTests.swift | pesoParaIdadeAlemDe121Meses | peso estendido a 229 | | | planned |
| growth-reference-data | IMC de meninos aos 61,5 meses | GrowthReferenceDataTests.swift | imcDeMeninosAos61eMeioMeses | sem interpolação | | | planned |
| growth-reference-data | Último intervalo válido de estatura | GrowthReferenceDataTests.swift | ultimoIntervaloValidoDeEstatura | linha 229 descartada | | | planned |
| growth-reference-data | Mês superior ausente | GrowthReferenceDataTests.swift | mesSuperiorAusente | devolve linha inferior | | | planned |
| growth-reference-data | Mês inferior ausente | GrowthReferenceDataTests.swift | mesInferiorAusente | devolve linha superior | | | planned |
| growth-reference-data | Recurso embutido completo | GrowthReferenceDataTests.swift | recursoEmbutidoCompleto | recurso fora do bundle | | | planned |
| growth-reference-data | Recurso com dia faltando | GrowthReferenceDataTests.swift | recursoComDiaFaltando | sem validação de lacuna | | | planned |
| growth-reference-data | Linha +2 DP no dia 0 de peso de meninos | GrowthReferenceDataTests.swift | linhaMais2DpNoDia0DePesoDeMeninos | expoente L em vez de 1/L | | | planned |
| growth-reference-data | Número de pontos e limite superior de peso | GrowthReferenceDataTests.swift | numeroDePontosELimiteSuperiorDePeso | amostragem diária | | | planned |
| growth-reference-data | Percentil 50 igual à mediana | GrowthReferenceDataTests.swift | percentil50IgualAMediana | offset errado no P50 | | | planned |
| growth-reference-data | Limite superior das curvas de IMC | GrowthReferenceDataTests.swift | limiteSuperiorDasCurvasDeImc | filtro de 228 removido | | | planned |
| anthropometric-computation | Idade de uma criança de cinco anos | AnthropometricComputationTests.swift | idadeDeUmaCriancaDeCincoAnos | fuso local | | | planned |
| anthropometric-computation | Nascimento depois da visita | AnthropometricComputationTests.swift | nascimentoDepoisDaVisita | idade negativa sem erro | | | planned |
| anthropometric-computation | Meses fracionados | AnthropometricComputationTests.swift | mesesFracionadosViramDias | truncamento | | | planned |
| anthropometric-computation | Dois anos exatos | AnthropometricComputationTests.swift | doisAnosExatosViram731Dias | arredondamento bancário | | | planned |
| anthropometric-computation | Último dia dos padrões e primeiro da referência | AnthropometricComputationTests.swift | ultimoDiaDosPadroesEPrimeiroDaReferencia | `<` no lugar de `<=` | | | planned |
| anthropometric-computation | Última idade válida e primeira fora dos limites | AnthropometricComputationTests.swift | ultimaIdadeValidaEPrimeiraForaDosLimites | meses fracionados no limite | | | planned |
| anthropometric-computation | Sexo ausente | AnthropometricComputationTests.swift | sexoAusenteZeraResultados | assume menino | | | planned |
| anthropometric-computation | Idade ausente | AnthropometricComputationTests.swift | idadeAusenteDaFaixaDesconhecida | assume 0 dias | | | planned |
| anthropometric-computation | Comprimento medido em pé | AnthropometricComputationTests.swift | comprimentoMedidoEmPeSoma07 | limiar 730 | | | planned |
| anthropometric-computation | Altura medida deitada | AnthropometricComputationTests.swift | alturaMedidaDeitadaSubtrai07 | ajuste omitido | | | planned |
| anthropometric-computation | Referência ignora o modo de medida | AnthropometricComputationTests.swift | referenciaIgnoraOModoDeMedida | ajuste na referência | | | planned |
| anthropometric-computation | Peso com três casas | AnthropometricComputationTests.swift | pesoComTresCasasArredondaAntes | sem arredondar entrada | | | planned |
| anthropometric-computation | Peso ausente | AnthropometricComputationTests.swift | pesoAusenteZeraPesoEImc | peso nulo vira 0 | | | planned |
| anthropometric-computation | IMC de 20 kg e 110 cm | AnthropometricComputationTests.swift | imcDe20KgE110Cm | cm sem dividir por 100 | | | planned |
| anthropometric-computation | IMC absurdo | AnthropometricComputationTests.swift | imcAbsurdoEIndefinido | teto removido | | | planned |
| anthropometric-computation | Estatura em +2 DP | AnthropometricComputationTests.swift | estaturaEmMais2Dp | divide por L | | | planned |
| anthropometric-computation | Estatura além de +3 DP não é ajustada | AnthropometricComputationTests.swift | estaturaAlemDe3DpNaoEAjustada | clamp em 3.00 | | | planned |
| anthropometric-computation | Medida inválida | AnthropometricComputationTests.swift | medidaInvalidaZeraEstatura | mínimo removido | | | planned |
| anthropometric-computation | Peso acima de +3 DP | AnthropometricComputationTests.swift | pesoAcimaDe3DpUsaAjuste | ramo z > 3 removido | | | planned |
| anthropometric-computation | Peso abaixo de -3 DP | AnthropometricComputationTests.swift | pesoAbaixoDeMenos3DpUsaAjuste | ramo z < -3 errado | | | planned |
| anthropometric-computation | Peso dentro de 3 DP | AnthropometricComputationTests.swift | pesoNaMedianaDaZeroEPercentil50 | percentil sem casa | | | planned |
| anthropometric-computation | Criança com edema | AnthropometricComputationTests.swift | criancaComEdemaZeraPesoEImc | IMC mantido com edema | | | planned |
| anthropometric-computation | Peso abaixo do mínimo | AnthropometricComputationTests.swift | pesoAbaixoDoMinimoZeraPeso | mínimo removido | | | planned |
| anthropometric-computation | Última idade com peso para idade | AnthropometricComputationTests.swift | ultimaIdadeComPesoParaIdade | linha 121 omitida | | | planned |
| anthropometric-computation | Primeira idade sem peso para idade | AnthropometricComputationTests.swift | primeiraIdadeSemPesoParaIdade | clamp no último mês | | | planned |
| anthropometric-computation | Percentis de z conhecidos | AnthropometricComputationTests.swift | percentisDeZConhecidos | ramo negativo errado | | | planned |
| anthropometric-computation | Percentil além de 3 DP | AnthropometricComputationTests.swift | percentilAlemDe3DpEIndefinido | corte sobre z arredondado | | | planned |
| anthropometric-computation | Empates longe de zero | AnthropometricComputationTests.swift | empatesArredondamLongeDeZero | arredondamento bancário | | | planned |
| anthropometric-computation | Valor indefinido | AnthropometricComputationTests.swift | valorIndefinidoContinuaIndefinido | nil vira 0 | | | planned |
| anthropometric-computation | Soma binária imprecisa | AnthropometricComputationTests.swift | somaBinariaImprecisaViraDecimalExato | Decimal(Double) direto | | | planned |
| anthropometric-computation | Valor não finito | AnthropometricComputationTests.swift | valorNaoFinitoViraNil | infinito vira máximo | | | planned |
| anthropometric-computation | Limites dos intervalos | AnthropometricComputationTests.swift | limitesDosIntervalosDePlausibilidade | limite de peso 6 | | | planned |
| anthropometric-computation | Peso e estatura implausíveis ao mesmo tempo | AnthropometricComputationTests.swift | pesoEEstaturaImplausiveisAoMesmoTempo | ordem trocada | | | planned |
| anthropometric-computation | Fronteiras das faixas | AnthropometricComputationTests.swift | fronteirasDasFaixasDeGravidade | `<=` nas fronteiras | | | planned |
| anthropometric-computation | Negativo extremo e indefinido | AnthropometricComputationTests.swift | negativoExtremoEIndefinido | sem valor absoluto | | | planned |
| anthropometric-computation | Peso para idade aos 121 meses informados | AnthropometricComputationTests.swift | pesoParaIdadeAos121MesesInformados | meses recalculados dos dias | | | planned |
| anthropometric-computation | Fixture de padrões | GoldenParityTests.swift | fixtureDePadroesBateComAnthro | limiar de 0,7 cm errado | | | planned |
| anthropometric-computation | Fixture de referência | GoldenParityTests.swift | fixtureDeReferenciaBateComAnthroplus | sem interpolação | | | planned |

## Test Changes After Red

<!-- Append-only. Vazio no planejamento. -->
