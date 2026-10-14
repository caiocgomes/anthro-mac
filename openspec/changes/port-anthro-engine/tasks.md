# Tasks

## 0. Red gate

- [ ] 0.1 Write every scenario test from tests.md (`GrowthReferenceDataTests.swift`, `AnthropometricComputationTests.swift`, `GoldenParityTests.swift`) and stubs with the exact signatures from Interface Under Test (neutral return values per design D9, no logic); inclui `scripts/golden/generate_golden.R` (biblioteca local `.rlib/`, semente fixa, 600 + 600 casos e grade de bordas, exclusão de peso aos 121.0 meses registrada no cabeçalho) e as fixtures `Tests/AnthroCoreTests/Fixtures/golden-standards.csv` e `golden-reference.csv`, idênticas em duas execuções, porque os testes de paridade as leem
- [ ] 0.2 Run the scenario tests (`swift test --filter AnthroCoreTests`); confirm each FAILS BY ASSERTION (not import, syntax or collection errors); record each failure excerpt in the ledger
- [ ] 0.3 Commit tests, stubs, fixtures and the golden script only as `test(red): port-anthro-engine`; write the SHA in the ledger
- [ ] 0.4 STOP: show the user the failing tests and wait for explicit approval before implementing

## 1. Dados de referência (growth-reference-data)

- [ ] 1.1 Implementar `scripts/generate_who_tables.py` (uv + openpyxl): ler as seis planilhas expandidas e os três CSV do pacote R, conferir dias 0 a 1826 contra o pacote R `anthro`, escrever `Sources/AnthroCore/Resources/who/{std,ref}-{wfa,lhfa,bfa}.csv`; verificado quando duas execuções seguidas não produzem diff (`git diff --exit-code Sources/AnthroCore/Resources/who`)
- [ ] 1.2 Declarar o recurso `Resources/who` no target `AnthroCore` e implementar `GrowthReferenceTables.load` e `bundled()` com validação de contiguidade, unit tests first (inner loop: parser de linha, erro de linha malformada); verified when [tests: recursoEmbutidoCompleto, recursoComDiaFaltando, linhaDoDia0DePesoParaIdadeDeMeninos, ultimoDiaDosPadroesDeImcDeMeninas, diaAlemDoFimDosPadroes, mes61DeImcParaIdadeDeMeninos, pesoParaIdadeAlemDe121Meses] pass
- [ ] 1.3 Implementar `referenceLMS` com a regra de par de `Get4AgeIndicatorDataPoint` e `GetInterpolatedValue`; verified when [tests: imcDeMeninosAos61eMeioMeses, ultimoIntervaloValidoDeEstatura, mesSuperiorAusente, mesInferiorAusente] pass
- [ ] 1.4 Implementar `GrowthCurves.points` (offsets de DP e de percentil, amostragem de 4 dias, limites 120 e 228); verified when [tests: linhaMais2DpNoDia0DePesoDeMeninos, numeroDePontosELimiteSuperiorDePeso, percentil50IgualAMediana, limiteSuperiorDasCurvasDeImc] pass
- [ ] 1.5 Refactor `GrowthReferenceTables` e `GrowthCurves`; `swift test` stays green

## 2. Núcleo numérico (anthropometric-computation)

- [ ] 2.1 Implementar `ClinicalRounding.round` e `decimal15`, unit tests first (inner loop: zero, negativos, 15 dígitos em 1/3); verified when [tests: empatesArredondamLongeDeZero, valorIndefinidoContinuaIndefinido, somaBinariaImprecisaViraDecimalExato, valorNaoFinitoViraNil] pass
- [ ] 2.2 Implementar `AgeMath` (dias em UTC, meses, `monthsToDays`, `ageRange`); verified when [tests: idadeDeUmaCriancaDeCincoAnos, nascimentoDepoisDaVisita, mesesFracionadosViramDias, doisAnosExatosViram731Dias, ultimoDiaDosPadroesEPrimeiroDaReferencia] pass
- [ ] 2.3 Implementar `Anthropometry.adjustedLengthOrHeight` e `exactBMI`; verified when [tests: comprimentoMedidoEmPeSoma07, alturaMedidaDeitadaSubtrai07, imcDe20KgE110Cm, imcAbsurdoEIndefinido] pass
- [ ] 2.4 Implementar `ZScore.lms` (fórmula LMS, ramos ajustados, valor não finito vira nil) e `ZScore.centile` com os coeficientes truncados, unit tests first (inner loop: L negativo, z exatamente -3 e 3); verified when [tests: estaturaEmMais2Dp, estaturaAlemDe3DpNaoEAjustada, pesoAcimaDe3DpUsaAjuste, pesoAbaixoDeMenos3DpUsaAjuste, percentisDeZConhecidos, percentilAlemDe3DpEIndefinido] pass
- [ ] 2.5 Implementar `AnthroEngine.result` (arredondamento de entradas, faixa, sexo, edema, mínimos, peso só até 121 meses, meses informados preservados) e a sobrecarga por datas; verified when [tests: ultimaIdadeValidaEPrimeiraForaDosLimites, sexoAusenteZeraResultados, idadeAusenteDaFaixaDesconhecida, referenciaIgnoraOModoDeMedida, pesoComTresCasasArredondaAntes, pesoAusenteZeraPesoEImc, medidaInvalidaZeraEstatura, pesoNaMedianaDaZeroEPercentil50, criancaComEdemaZeraPesoEImc, pesoAbaixoDoMinimoZeraPeso, ultimaIdadeComPesoParaIdade, primeiraIdadeSemPesoParaIdade, pesoParaIdadeAos121MesesInformados] pass
- [ ] 2.6 Implementar `Plausibility` e `SeverityClassifier`; verified when [tests: limitesDosIntervalosDePlausibilidade, pesoEEstaturaImplausiveisAoMesmoTempo, fronteirasDasFaixasDeGravidade, negativoExtremoEIndefinido] pass
- [ ] 2.7 Rodar a paridade e investigar cada divergência pela causa raiz antes de qualquer ajuste; verified when [tests: fixtureDePadroesBateComAnthro, fixtureDeReferenciaBateComAnthroplus] pass
- [ ] 2.8 Refactor `AnthroEngine` e helpers numéricos (nomes, duplicação entre ramos ajustados); `swift test` stays green

## 3. Verification

- [ ] 3.1 Mutation check for growth-reference-data: trocar a regra de par da interpolação por "sempre mês inferior", ver `imcDeMeninosAos61eMeioMeses` falhar, reverter
- [ ] 3.2 Mutation check for anthropometric-computation: remover o ramo `z > 3` de `ZScore.lms`, ver `pesoAcimaDe3DpUsaAjuste` falhar, reverter
- [ ] 3.3 Mutation check for anthropometric-computation: trocar `<= 1856` por `< 1856` em `AgeMath.ageRange`, ver `ultimoDiaDosPadroesEPrimeiroDaReferencia` falhar, reverter
- [ ] 3.4 Run the full suite fresh (`swift test`); all green, output free of errors and warnings

## Workflow follow-up

- Produce evidence.md (`openspec instructions evidence --change port-anthro-engine`) and reach `DECISION: PASS`
- Atualizar `docs/reverse-engineering-findings.md` com as divergências encontradas pela paridade, se houver
- Archive the change
