# Evidence

Gerado em 14/10/2026, 13h. Pré-checagens: commit vermelho `0da1e12` encontrado por `git log --format=%h --grep='^test(red)' -n 1` (filtrado pela change); `git rev-list --count 0da1e12..HEAD` = 15; tarefas não marcadas em `tasks.md` = 0.

## Red Gate Replay

- **Red commit**: `0da1e12` (`test(red): port-anthro-engine`)
- **How replayed**: worktree temporário destacado em `0da1e12` (`git worktree add --detach`), `swift test --filter AnthroCoreTests`, worktree removido em seguida.
- **Result**: 53 testes de cenário executados, 53 falharam, 0 passaram, 0 erros capturados ou fatais. Todas as falhas são de asserção (`Expectation failed` ou `#require`). Os dois testes de paridade carregaram as fixtures (passaram em `count == 600`) e falharam na comparação (diferença 99, 0 casos idênticos).

## Test Freeze

- **Command**: `git diff 0da1e12..HEAD --stat -- Tests/AnthroCoreTests/GrowthReferenceDataTests.swift Tests/AnthroCoreTests/AnthropometricComputationTests.swift Tests/AnthroCoreTests/GoldenParityTests.swift Tests/AnthroCoreTests/TestSupport.swift Tests/AnthroCoreTests/Fixtures/`
- **Changes found**: só `Tests/AnthroCoreTests/Fixtures/golden-standards.csv` (601 linhas trocadas). Corresponde à entrada de 14/10/2026 em tests.md "Test Changes After Red": o gerador passou a excluir medida em pé abaixo de 9 meses, onde o pacote `anthro` descarta o tipo de medida e o original soma 0,7 cm; asserções inalteradas; spec emendada no cenário "Fixture de padrões". Os arquivos `.swift` de cenário não mudaram. Testes acrescentados depois do vermelho são do laço interno (`ClinicalRoundingUnitTests`, `GrowthReferenceTablesUnitTests`, `ZScoreUnitTests`), cada um visto falhando antes do código.

## Mutation Checks

| Capability | Mutation applied | Test that caught it | Reverted |
|------------|------------------|---------------------|----------|
| growth-reference-data | interpolação trocada por "sempre a linha do mês inteiro inferior" | `imcDeMeninosAos61eMeioMeses` (recebeu a linha de 61 meses no lugar da média com 62) | sim (`git diff` vazio) |
| anthropometric-computation | ramo `z > 3` removido de `ZScore.lms` | `pesoAcimaDe3DpUsaAjuste` (3.92 no lugar de 4.00) | sim (`git diff` vazio) |
| anthropometric-computation | `days <= 1856` trocado por `days < 1856` em `AgeMath.ageRange` | `ultimoDiaDosPadroesEPrimeiroDaReferencia` (1856 dias virou `.reference`) | sim (`git diff` vazio) |

## Full Suite

- **Command**: `swift test` (depois de `rm -rf .build` e build limpo dos testes)
- **Result**: 96 passed, 0 failed, 0 skipped (53 de cenário desta change, 5 do laço interno desta change, 38 da `bootstrap-macos-app`)
- **Output clean**: sim; build e testes sem `warning:` nem `error:`.
- **Paridade medida por sonda descartável** (não versionada): 600 de 600 casos idênticos em `golden-standards.csv` (1.738 z-scores) e 600 de 600 em `golden-reference.csv` (1.372 z-scores), diferença máxima 0.
- **Recursos**: `scripts/generate_who_tables.py` conferiu os dias 0 a 1826 das planilhas da OMS contra o pacote R `anthro` (iguais) e gera saída idêntica em duas execuções; `scripts/golden/generate_golden.R` também é determinístico. `scripts/build-app.sh` gera e assina o `.app` com o autoteste passando.

## TDD Path

TDD path: superpowers

## OpenSpec Verify

Verificação feita pelo critério do `openspec-verify-change` em 14/10/2026:

- **CRITICAL**: nenhum. 21 de 21 tarefas; 23 requisitos ADDED com implementação em `Sources/AnthroCore/`; 53 cenários com teste de mesmo nome.
- **Design**: D1 (conversões de 15 dígitos em `ClinicalRounding.decimal15`), D2 (`nil` no lugar de `MinValue`), D3 (regra de par em `GrowthReferenceTables.referenceLMS`), D4 (CSV gerado e lido por `AnthroCoreResources.whoDirectory`, sem `Bundle.module` direto), D5 (curvas em `Double`), D6 (fixtures por R com as exclusões registradas no cabeçalho), D7 (coeficientes truncados em `ZScore.centile`) e D8 (dia de calendário do usuário em `AgeMath.ageInDays`) seguidos.
- **WARNING**: o autoteste do `.app` (`SelfTest.run`, change 1) ainda confere só o `README.txt` do bundle de recursos; o design da change 1 previa que a change 2 passasse a carregar `GrowthReferenceTables.bundled()`, mas isso não entrou nas tarefas desta change. Recomendação: acrescentar à `add-anthropometric-calculator`, a primeira change que usa as tabelas dentro do `.app`.

## Decision

DECISION: PASS
