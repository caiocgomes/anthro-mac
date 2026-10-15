# Evidence

## Red Gate Replay

- **Red commit**: `9d785b8` (`git log --format=%h --grep='^test(red)' -n 1`); 10 commits depois dele na primeira checagem (`git rev-list --count 9d785b8..HEAD`); nenhuma tarefa aberta em tasks.md.
- **How replayed**: worktree temporário em `9d785b8` (`git worktree add --detach`), `swift test --filter` com as 9 suítes de cenário da change, worktree removido em seguida.
- **Result**: 47 testes de cenário; os 47 falharam por asserção, nenhum por erro lançado, falha de compilação ou queda do processo. 40 falharam por `Expectation failed` e 7 por `Issue.record` explícito do helper `expectInvalidStructure`, que registra a falha quando a leitura não lança `ImportFailure.invalidStructure`. Na suíte completa do mesmo SHA, 541 testes, só esses 47 falhavam. Trechos de cada falha no ledger de tests.md.
- **Portão vermelho**: registrado sem parada (tarefa 0.4), por decisão do Caio de 14/10/2026: a parada vale só para as changes que fixam números clínicos (`port-anthro-engine` e `add-survey-analysis`).

## Test Freeze

- **Command**: `git diff --name-status 9d785b8..HEAD -- Tests/`, separando os arquivos de cenário, suporte e fixtures dos unitários.
- **Changes found**: um arquivo de cenário mudou, `Tests/AnthroFeaturesTests/IndividualExchange/ChildExchangeModelTests.swift`, só no teste `duasCriancasMarcadasEmCsvGeramTresLinhas` (+8 -1), e a mudança está registrada em "Test Changes After Red": o cenário esperava 43 campos no cabeçalho, mas a exportação acrescenta as 7 colunas do modelo padrão de dados adicionais que a migração 4 da change 6 grava, como o requisito "Colunas da exportação delimitada" pede e o original faz numa instalação nova. O texto do cenário na spec foi ajustado junto. Suporte e fixtures intactos. Os demais arquivos tocados são 8 arquivos novos de testes unitários do laço interno (`FieldUnitTests`, `DelimitedWriterUnitTests`, `ExchangeValuesUnitTests`, `ChildXMLUnitTests`, `ChildReportUnitTests`, `DaylightSavingUnitTests`, `ChildExchangeMappingUnitTests`, `ChildExchangeModelUnitTests`).
- **Ajuste anterior ao vermelho** (`c368199`): datas ao meio-dia do calendário local nos testes e na leitura (D5), inits públicos das estruturas de troca, resultados vazios para visita anterior ao nascimento (D11) e gatilho SQLite para simular a falha no meio da gravação.

## Mutation Checks

| Capability | Mutation applied | Test that caught it | Reverted |
|------------|------------------|---------------------|----------|
| individual-data-exchange (formato, tarefa 6.1) | separador de `DelimitedFormat.semicolonCSV` trocado para `,` | `cabecalhoSemResultadosTem43ColunasNaOrdemOriginal` (`header.count -> 1 == 43`) | sim (`git checkout`) |
| individual-data-exchange (importação, tarefa 6.2) | `<=` trocado por `<` na checagem de datas de visita | `duasVisitasNaMesmaDataRejeitaComValorInvalido` | sim |
| individual-data-exchange (gravação, tarefa 6.3) | `insertAll` sem `AnthroDatabase.transaction` | `falhaNoMeioDaGravacaoDesfazTudo` (`count("children") == 0`) | sim |
| individual-data-exchange | escrita de atributo sem as referências de tabulação e quebra de linha | `tabsAndLineBreaksInTextSurviveTheRoundTrip` | sim |
| individual-data-exchange | `CreatedBy` da visita aceito ausente | `visitCreatedByIsRequiredButChildCreatedByIsNot` | sim |
| individual-data-exchange | relatório sem ordenar as visitas pela data | `visitsAreListedChronologicallyAndFootnoteCloses` | sim |

As três últimas linhas cobrem testes unitários escritos depois do código do leitor e do relatório; passaram de primeira, então a mutação é o que mostra que eles detectam a quebra.

## Full Suite

- **Command**: `swift package clean && swift test`
- **Result**: 574 testes passaram, 0 falharam, 0 pulados (494 anteriores, 47 cenários e 33 unitários desta change); código de saída 0. Rodada do zero no estado que virou o commit `747a777` (antes, 573 no estado de `33904a3`).
- **Output clean**: sim; nenhuma linha com `warning:` ou `error:` na saída do build e dos testes.
- **App**: `scripts/build-app.sh` terminou com código 0 (autoteste positivo), sem avisos, e `codesign --verify build/AnthroPlus.app` com código 0 (critério mecânico da tarefa 5.3), no estado de `33904a3`. A reconstrução só roda depois de `pgrep -x AnthroPlusApp` confirmar o app fechado; na segunda verificação o app estava aberto (PID 35464) e o bundle não foi refeito, então ele não tem a última correção, que só tira do aviso de importação os campos descartados.
- **Verificação manual (5.3, N/A não executável)**: menus, painéis de abrir e salvar e a folha de exportação não foram exercidos; a regra do projeto é não enviar entrada sintética à interface. Fica para o Caio: marcar crianças e exportar nos três formatos, abrir o CSV no Numbers, importar o XML exportado num banco novo e gerar o relatório da criança aberta.

## TDD Path

TDD path: superpowers

## OpenSpec Verify

Verificação mecânica (tarefas, requisitos, cenários, ledger, congelamento) mais uma revisão independente de código, só de leitura, que rodou o código real numa cópia das fontes com sondas para fuso horário, ida e volta, banco e estrutura do XML.

| Dimension | Status |
|-----------|--------|
| Completeness | 28/28 tarefas; 20 requisitos ADDED, todos com implementação localizada |
| Correctness | 20/20 requisitos mapeados; 47/47 cenários com teste verde no ledger, um deles com expectação corrigida e registrada |
| Coherence | D1 a D16 seguidas; decisões da implementação e da revisão em D17 |

- **CRITICAL, corrigido** (`33904a3`): datas do dia em que começava o horário de verão eram recusadas. O leitor usava um formatador estrito no fuso do usuário, e a meia-noite desse dia não existe em São Paulo (por exemplo 16/10/2016 e 04/11/2018). Pela regra de rejeitar o arquivo inteiro, uma só data assim, de criança, mãe, pai ou visita, impedia a importação; o próprio XML exportado pelo Mac de uma criança nascida em 2016-10-16 não voltava. Agora o texto é lido em UTC e vira o meio-dia do dia no fuso do usuário. Testes: `transitionDaysAreReadInAnyTimeZone` (determinístico, com o fuso de São Paulo) e `publicReaderAcceptsTransitionDaysInTheUsersTimeZone`, que falharam antes da correção.
- **CRITICAL, corrigido** (`33904a3`): um `Child` dentro de outro `Child` derrubava o app por índice fora do intervalo. Agora é estrutura inválida. Teste: `nestedChildIsInvalidStructureNotACrash`.
- **CRITICAL, mitigado e encaminhado**: o importador corta textos nos limites do original (nomes 50, observações 250, CEP 15, telefone 20), como a spec pede, mas os editores do Mac, da change 4, não limitam o tamanho. Uma observação ou um endereço longo digitado no Mac e exportado volta cortado ao ser reimportado. A importação agora avisa quantos textos foram cortados, com o primeiro caso (`importWarnsWhenTextsWereCutToTheOriginalLimits`); impor os limites nos editores da change 4 fica como decisão do Caio.
- **WARNING, corrigidos** (`33904a3`):
  - `Mother`, `Father`, `Address` e `Visit` fora de `Child` eram descartados em silêncio; agora são estrutura inválida (`elementsOutsideAChildAreInvalidStructure`).
  - uma visita com dados adicionais ilegíveis no banco bloqueava a exportação de todas as crianças com mensagem em inglês; agora a mensagem em pt-BR diz a criança e a data da visita (`unreadableAdditionalDataStopsExportWithAClearMessage`).
- **SUGGESTION, aplicadas**: `DisplayID` acima de 2147483647 recusado como no original (`displayIDAboveTheOriginalIntegerIsInvalidStructure`); exportar a criança aberta com alterações pendentes pede para salvar antes (camada de view, sem teste automatizado).
- **SUGGESTION, registradas sem mudança**: visita sem dados adicionais volta da ida e volta com dados vazios (D17), sem mudar valor; o corte de texto conta caracteres, e o Windows conta unidades UTF-16 (só difere com emoji ou caracteres combinados acima do limite).
- **Conferido e correto pela revisão**: transação reentrante com rollback completo, mãe, pai e endereço ligados à criança certa, `DisplayID` preservado, visitas gravadas com a criança certa, colunas alinhadas em TXT e CSV com ou sem pais, endereço e visitas, aspas, BOM e CRLF, IMC com a medida ajustada, caracteres especiais na ida e volta pelo XML, limites de peso e medida, ordem das visitas, layout do relatório e exportação na ordem da lista.
- **Não verificado**: compatibilidade com um XML gerado de fato pelo AnthroPlus de Windows (não há arquivo real nesta máquina; a fixture segue o layout lido no código); interface em execução (5.3). Datas com dia e mês de um dígito (`1/4/2021`) foram conferidas à parte: o formatador estrito as aceita, como o `DateTime.Parse` em pt-BR.

### Segunda verificação (`/opsx:verify` formal, 14/10/2026, 21h33)

- **Completeness**: 28/28 tarefas, nenhum arquivo de rastreio inacessível; 20 requisitos ADDED com implementação localizada.
- **Correctness**: os 47 cenários passam no estado atual; o texto de cada requisito conferido contra o código, inclusive o das correções da revisão (`33904a3`), que nenhuma revisão tinha visto.
- **WARNING, corrigido** (`747a777`): o aviso de textos cortados contava também `CreatedBy` e os níveis SALB, que a importação lê e descarta; um `CreatedBy` longo ou um código SALB maior que 3 avisaria de um corte num valor que o app nem guarda. Teste `discardedFieldsDoNotCountAsTruncatedTexts`, que falhou antes da correção com cinco avisos falsos.
- **WARNING, corrigido no artefato**: a tabela Interface Under Test não tinha `ChildXML.readReport`, `ChildExchangeModel.lastImportWarning` nem `ChildExchangeError`, acrescentados pelas correções da revisão; agora tem.
- **SUGGESTION, corrigido no artefato**: o requisito "Ida e volta pelo XML" dizia "os mesmos valores de campo", mas a visita sem dados adicionais volta com dados adicionais vazios (D8 e D17); o requisito passou a dizer isso. Nenhum cenário mudou.
- **Não verificado**: interface em execução (5.3) e arquivo real do AnthroPlus de Windows, como na primeira passada.

## Decision

DECISION: PASS
