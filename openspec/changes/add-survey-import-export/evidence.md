# Evidence

## Red Gate Replay

- **Red commit**: `e12fb0e` (`git log --format=%h --grep='^test(red)' -n 1`). Na checagem havia 7 commits depois dele (`git rev-list --count e12fb0e..HEAD`) e nenhuma tarefa aberta em tasks.md.
- **How replayed**: worktree temporário em `e12fb0e` (`git worktree add --detach`), `swift test --filter` com as 13 suítes de cenário da change, worktree removido em seguida. A mesma worktree, levada a cada commit verde (`4e646f5`, `9f9b6b6`, `c05affa`, `8642bc4`, `205b269`), deu o SHA verde de cada linha do ledger. Seis nomes com dígitos escaparam do filtro de texto da contagem e foram atribuídos pelo commit que implementou a suíte deles.
- **Result**:
  - 68 testes de cenário rodaram e os 68 falharam por asserção. Nenhum passou, nenhum lançou erro, nenhum falhou na compilação ou derrubou o processo.
  - A saída tem 86 `Expectation failed` e 16 registros explícitos do helper `expectInvalidStructure`. O helper registra a falha quando a leitura não lança `ImportFailure.invalidStructure`.
  - Na suíte completa do mesmo SHA (642 testes), só esses 68 falhavam.
  - Os trechos de cada falha estão no ledger de tests.md.
  - No commit `205b269` os 68 passam.
- **Portão vermelho**: registrado sem parada (tarefa 0.4), por decisão do Caio de 14/10/2026 e pela meta de 15/10/2026. A parada vale só para as changes que fixam números clínicos.

## Test Freeze

- **Command**: `git diff --stat e12fb0e..HEAD -- <os 18 arquivos de teste do commit vermelho>`. Os 18 são as 13 suítes de cenário, o suporte (`SurveyExchangeFixtures`, `DBFBuilder`, `SurveyExchangeTestSupport`) e as fixtures (`survey.rec`, `ns-two-surveys.xml`).
- **Changes found**: nenhuma; o comando não lista arquivo. `git diff --name-status e12fb0e..HEAD -- Tests` só mostra sete arquivos novos de testes unitários do laço interno:
  - `SurveyTextUnitTests`
  - `SurveyBinaryUnitTests`
  - `ExternalSurveyBuilderUnitTests`
  - `SurveyXMLUnitTests`
  - `SurveyDelimitedExportUnitTests`
  - `SurveyReviewUnitTests`
  - `SurveyExchangeUnitTests`
- **Unitários alterados depois de escritos**: dois asserts de `SurveyTextUnitTests` seguiram as regras da revisão (D20).
  - Uma linha `;` deixou de virar registro vazio.
  - O padrão da extensão, quando aparece na linha, passou a vencer a contagem.
  - Nenhum teste de cenário mudou, e "Test Changes After Red" continua vazio.

## Mutation Checks

| Capability | Mutation applied | Test that caught it | Reverted |
|------------|------------------|---------------------|----------|
| survey-data-exchange (leitura, tarefa 6.1) | salto de espaços iniciais de `DelimitedParser` desligado (`if false, atStart, ...`) | `espacoInicialEAspasDuplicadasSaoTratados` (`rows == [["15", "a\"b"]]`) | sim; refeita depois das correções da revisão, com o mesmo resultado |
| survey-data-exchange (montagem, tarefa 6.2) | limite de registros descartados listados de 10 para 20 | `dozeRegistrosComSexoInvalidoListamDez` (`rowErrors.count -> 12 == 10`) | sim |
| survey-data-exchange (XML, tarefa 6.3) | `HC` ignorado (`isWHOAnthro = false`) | `arquivoDoWhoAnthroConverteDiasEmMeses` (`ageInMonths -> 1843`) | sim |
| survey-data-exchange (gravação, tarefa 6.4) | `insertAll` sem `AnthroDatabase.transaction` | `falhaNaGravacaoDoSegundoInqueritoDesfazTudo` (`count("surveys") == 0` e `count("records") == 0`) | sim |
| survey-data-exchange (XML) | `Record` fora de `Survey` aceito | `recordOutsideSurveyAndNestedSurveyAreInvalid` | sim |
| survey-data-exchange (XML) | `HC` decidido a cada registro, não no primeiro do arquivo | `whoAnthroFlagComesFromTheFirstRecordOfTheFile` | sim |
| survey-data-exchange (XML) | `AdditionalDataDef` sem validação | `unreadableAdditionalDataDefinitionOrValuesAreInvalid` | sim |
| survey-data-exchange (XML) | atributo escrito sem o escape | `writerOmitsEmptyDefinitionAndWritesDefaultAdditionalData` e `controlCharactersInNotesDoNotBreakTheFile` | sim |

As quatro últimas linhas cobrem testes unitários do XML que foram escritos depois do código e passaram de primeira. A mutação mostra que eles detectam a quebra.

Os testes da revisão independente (`SurveyReviewUnitTests` e a seção "Achados da revisão" de `SurveyExchangeUnitTests`) foram escritos antes das correções, e cada um foi visto falhando. Um REC malformado derrubava o processo de teste com `Fatal error: Range requires lowerBound <= upperBound`. Dois testes passaram de primeira e ficam como guarda:
- a medida deitada derivada das datas quando a idade digitada sai;
- as colunas extras do rascunho chegando ao banco ao salvar.

## Full Suite

- **Command**: `swift package clean && swift test`
- **Result**: 697 testes passaram, 0 falharam, 0 pulados, código de saída 0. São 574 anteriores, 68 cenários e 55 unitários desta change. Rodada do zero no estado do commit `e0c1f83`.
- **Output clean**: sim; nenhuma linha com `warning:` ou `error:` na saída do build e dos testes.
- **App**:
  - `scripts/build-app.sh` terminou com código 0, autoteste positivo e sem avisos, e `codesign --verify build/AnthroPlus.app` também com código 0. Esse é o critério mecânico da tarefa 5.3.
  - Estado: `e0c1f83`.
  - A reconstrução só rodou depois de `pgrep -x AnthroPlusApp` confirmar o app fechado.
- **Verificação manual (5.3, N/A não executável)**: a folha de associação, os painéis de abrir e salvar, a pergunta sobre o inquérito aberto e os avisos não foram exercidos, porque a regra do projeto é não enviar entrada sintética à interface. Fica para o Caio:
  - importar um CSV do Excel com uma linha de sexo inválido e confirmar o aviso;
  - importar o mesmo CSV com um inquérito aberto e alterado e responder à pergunta;
  - exportar dois inquéritos em CSV e em XML;
  - reimportar o XML num banco novo.

## TDD Path

TDD path: superpowers

## OpenSpec Verify

Os dois itens a seguir foram feitos antes do verify formal (`/opsx:verify`, registrado no fim do apply).

**Revisão independente, só leitura, sobre `3a325fb`:**
- Achou 8 defeitos e 8 sugestões, e os 8 defeitos foram corrigidos com teste antes (D20). Entre eles:
  - o ano com dois dígitos lido como ano 21;
  - o REC malformado que derrubava o app;
  - nomes de campo repetidos em REC e DBF;
  - textos cortados sem aviso na ida e volta pelo XML;
  - o XML sem `Survey` anunciado como gravado.
- Das sugestões, cinco foram adotadas:
  - o separador padrão vence quando aparece;
  - aspas abertas até o fim são formato inválido;
  - linhas só de separadores são ignoradas;
  - o separador é detectado na primeira linha não vazia;
  - a folha de exportação fecha antes do alerta.
- Três ficam como risco conhecido, fiéis ao original (D20):
  - booleanos só em inglês;
  - CSV em Mac Roman;
  - a contagem de linhas do aviso.

**Segunda revisão independente:** cobre só as correções, `9e52919..e0c1f83`.

## Decision

DECISION: PASS
