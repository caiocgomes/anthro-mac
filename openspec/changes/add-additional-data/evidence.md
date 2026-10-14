# Evidence

## Red Gate Replay

- **Red commit**: `d584f0f` (`git log --format=%h --grep='^test(red)' -n 1`); 13 commits depois dele na primeira checagem (`git rev-list --count d584f0f..HEAD`); nenhuma tarefa aberta em tasks.md.
- **How replayed**: worktree temporário em `d584f0f` (`git worktree add --detach`), `swift test --filter` com as 8 suítes de cenário da change, worktree removido em seguida. A migração 4 entrou no vermelho registrada com SQL vazio, como descrito em Conventions de tests.md, então os dois testes da migração falham contra ela sem fase separada.
- **Result**: 43 testes de cenário; os 43 falharam por asserção (`Expectation failed`), nenhum por erro lançado, falha de compilação ou queda do processo. No mesmo SHA, a suíte completa tinha 451 testes e só esses 43 falhavam. Trechos de cada falha no ledger de tests.md.
- **Portão vermelho**: registrado sem parada (tarefa 0.4), por decisão do Caio de 14/10/2026: a parada vale só para as changes que fixam números clínicos (`port-anthro-engine` e `add-survey-analysis`).

## Test Freeze

- **Command**: `git diff --name-status d584f0f..HEAD -- Tests/`, filtrando `ScenarioTests`, `Support/` e `Fixtures/`.
- **Changes found**: nenhuma em cenários, suporte ou fixtures; "Test Changes After Red" continua vazio. A lista completa tem só 9 arquivos novos de testes unitários do laço interno (`AdditionalDataUnitTests`, `AdditionalDataTemplateUnitTests`, `AdditionalDataEditorUnitTests`, `AdditionalDataLabelsUnitTests`, `AdditionalDataValuesUnitTests`, `VisitAdditionalDataUnitTests`, `IndividualAdditionalDataUnitTests`, `RecordAdditionalDataUnitTests`, `SurveyAdditionalDataUnitTests`).
- **Teste unitário corrigido no verde**: `changingToTextOrToSameKindKeepsIdentifierAndClearsValue`, escrito por mim no laço interno, fixava que escolher de novo o tipo já marcado apagava os limites; a revisão mostrou que o original não faz isso, e ele foi trocado por `choosingTheSameKindKeepsLimitsAndOtherKindClearsThem` antes da correção (falhou primeiro). Não é teste de cenário.
- **Ajuste anterior ao vermelho** (`b4dfd3e`): datas ao meio-dia do calendário local (D4), regra de dados não alterados (D11), modelo da visita lido do banco (D12), colunas dinâmicas a partir do macOS 14.4 (D13), assinaturas novas em Interface Under Test e migração 4 com SQL vazio no vermelho.

## Mutation Checks

| Capability | Mutation applied | Test that caught it | Reverted |
|------------|------------------|---------------------|----------|
| additional-data | atributos de `Num` na ordem `ID`, `Descr`, `Min`, `Max` em `AdditionalDataXML.encode` (tarefa 8.1) | `templateRoundTripIsByteIdentical` | sim (`git checkout`) |
| additional-data | sufixo de `AdditionalDataColumns.structure` começando em 1 (tarefa 8.2) | `duplicateAndForbiddenKeysGetNumericSuffix` (`["x", "x 1", "Sexo 1"]`) | sim |
| additional-data | modelo ausente no banco devolvendo dados vazios e gravação com `DO NOTHING` em `AdditionalDataTemplateRepository` | `missingRowFallsBackToOriginalDefault`, `savingTwiceKeepsOneRowWithTheLastTemplate` | sim |
| additional-data | descarte sem restaurar a definição em `SurveyDetailModel.discardChanges` | `discardRestoresSavedDefinitionAndColumns` | sim |
| additional-data | datas ordenadas antes de números em `SurveySortKey` | `mixedKindsSortNumbersThenDatesThenTextsThenMissing` | sim |
| additional-data | título de coluna sem o sufixo da chave | `repeatedKeyTitleKeepsTheSuffix` | sim |
| additional-data | indicador de ordenação mantido quando a coluna some da definição | `removingTheSortedColumnClearsTheSortIndicator` | sim |

As cinco últimas linhas cobrem testes unitários escritos depois do código (repositório e integração com o inquérito): passaram de primeira, então a mutação é o que mostra que eles detectam a quebra.

## Full Suite

- **Command**: `swift package clean && swift test`
- **Result**: 494 testes passaram, 0 falharam, 0 pulados (408 anteriores, 43 cenários e 43 unitários desta change); código de saída 0. Rodada do zero no estado que virou o commit `2efc83c` (antes, 493 no estado de `8bcff40`).
- **Output clean**: sim; nenhuma linha com `warning:` ou `error:` na saída do build e dos testes.
- **App**: `scripts/build-app.sh` terminou com código 0 (autoteste positivo), sem avisos, e `codesign --verify build/AnthroPlus.app` com código 0 (critério mecânico das tarefas 7.1 e 7.2), no estado de `2efc83c`. Nesta última reconstrução o app estava aberto (PID 7784, aberto às 20h40): a checagem imprimiu o processo, mas não interrompeu o script, em violação da regra do projeto. O script apaga o bundle e cria arquivos novos, então o processo aberto seguiu com o executável anterior (de `8bcff40`), sem queda nem relatório de falha; o banco não foi tocado. A instância aberta precisa ser reiniciada para usar o build atual.
- **Verificação manual (7.2, N/A não executável)**: não feita nesta sessão; a regra do projeto é não enviar entrada sintética à interface. Fica para o Caio: editar o modelo, criar visita e registro com valores, conferir as colunas na tabela do inquérito.

## TDD Path

TDD path: superpowers

## OpenSpec Verify

`/opsx:verify` mecânico mais uma revisão independente de código só de leitura, focada em perda de dado na junção entre modelos e telas.

| Dimension | Status |
|-----------|--------|
| Completeness | 31/31 tarefas; 21 requisitos ADDED, todos com implementação localizada |
| Correctness | 21/21 requisitos mapeados; 43/43 cenários com teste existente e verde no ledger |
| Coherence | D1 a D13 seguidas; decisões novas da implementação e da revisão registradas em D14 |

- **CRITICAL, corrigido** (`8bcff40`): o escritor do XML gravava caracteres de controle crus. Um valor ou identificador colado com a quebra suave do Word (U+000B) gerava XML que o próprio app não relê: o registro perdia todas as células adicionais e o formulário, a definição do inquérito perdia as colunas sem aviso, e o modelo da avaliação individual deixava o botão de gerenciar desabilitado na sessão seguinte. Agora o escritor só grava caracteres do XML 1.0 (U+000B e U+000C viram espaço). Teste: `pastedControlCharactersDoNotMakeUnreadableXML`, que falhou com `NSXMLParserErrorDomain Code=111` antes da correção.
- **WARNING, corrigidos** (`8bcff40`):
  - registro existente com XML `nil` recebia a definição do inquérito ao confirmar sem mudanças (inalcançável hoje; a importação da change 8 pode gravar NULL). Teste: `untouchedExistingRecordWithoutXMLStaysWithout`.
  - escolher de novo o tipo já marcado no editor de definição apagava mínimo e máximo. Teste: `choosingTheSameKindKeepsLimitsAndOtherKindClearsThem`.
- **SUGGESTION, aplicadas** (`8bcff40`): aplicar a definição sem mudança não regrava o texto nem marca pendência (teste `applyingAnUnchangedDefinitionKeepsTheStoredText`, que também impede um Return de trocar uma definição ilegível por `<Data />`); campos de número, identificador e limites enviam ao modelo no próprio setter da `Binding`; a data desmarcada e marcada de novo volta à última escolhida. As duas últimas são da camada de view, sem teste automatizado.
- **Conferido e correto pela revisão**: regra de D11 no nível dos modelos (XML intacto sem mudança, inclusive `nil` e ilegível na visita, número carregado sem truncar e sem bloquear fora do limite), mapeamento de seleção e painel do editor de definição, definição preservada em `save`, `discardChanges` e `applyOptions`, ordenação consistente com comparação localizada, cópia com as colunas adicionais mesmo abaixo do macOS 14.4, migração 4 e repositório.
- **Não verificado**: comportamento visual e de teclado das telas novas (tarefa 7.2), inclusive se o campo de texto do macOS mantém o U+000B colado e se o seletor segmentado reescreve o tipo ao ser clicado de novo (as duas correções valem nos modelos de qualquer forma); a tabela com colunas dinâmicas compila para macOS 14.4 ou mais e não foi aberta com dados.

### Segunda verificação (`/opsx:verify` formal, 14/10/2026, 20h41, em `5478669`)

- **Completeness**: 31/31 tarefas, nenhum arquivo de rastreio inacessível; 21 requisitos ADDED com implementação localizada.
- **Correctness**: os 43 cenários passam no `HEAD`; o texto de cada requisito conferido contra o código.
- **Coherence**: D1 a D14 conferidas; as correções da revisão (`8bcff40`) relidas, porque nenhuma revisão as tinha visto.
- **WARNING, corrigido** (`2efc83c`): a correção da revisão deixou de marcar pendência ao aplicar uma definição sem mudança, o que contraria o requisito "aplicar a definição SHALL marcar o inquérito com alterações pendentes" e o `tsbAddData_Click` do original, que chama `SetModified()` a cada OK. Agora marca pendência e mantém o texto gravado intacto (a proteção que importava). Teste `applyingAnUnchangedDefinitionMarksPendingButKeepsTheStoredText`, que falhou antes da correção.
- **WARNING, corrigido no artefato**: o requisito de escrita dizia "exatamente como `GetXML`", mas o escritor filtra caracteres fora do XML 1.0 desde `8bcff40`; o requisito passou a registrar a exceção (U+000B e U+000C como espaço). Nenhum cenário mudou.
- **SUGGESTION, corrigido** (`2efc83c`): depois de gravar o modelo da avaliação individual, a memória guardava o identificador sem o filtro, diferente do banco e das visitas novas; agora relê o banco. Teste `committedTemplateInMemoryMatchesWhatWasStored`, que falhou antes.
- **SUGGESTION, para a change 8**: uma definição ilegível que chegue por importação aparece como árvore vazia no editor do inquérito, sem aviso; o app não produz mais esse XML, então a validação cabe à importação.
- **Não verificado**: telas novas e tabela com colunas dinâmicas sem exercício na interface (7.2).

## Decision

DECISION: PASS
