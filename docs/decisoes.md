# Decisões tomadas sem consulta

Registro das decisões que tomei sozinho durante a implementação das changes OpenSpec, para o Caio revisar quando quiser. Cada item diz o que foi decidido, por quê e onde está o detalhe. O registro formal de cada change continua no `design.md` dela (itens "Decisões tomadas na implementação"); aqui fica o índice legível.

Legenda: **[desvio]** muda um comportamento observável do original; **[proteção]** evita perda de dado; **[forma]** é escolha de implementação sem efeito nos números.

## Perguntas em aberto para o Caio

1. **Versão do macOS do Mac da Suzan.** A tabela do inquérito só mostra as colunas de dados adicionais a partir do macOS 14.4; o pacote declara 14.0. Mantive o alvo e escolho a tabela na view (D13 de `add-additional-data`). Se o Mac dela tiver 14.4 ou mais, subo o alvo e o ramo degradado some.
2. **Limite de tamanho nos editores da Avaliação individual.** O original limita nomes e campos de endereço a 50 caracteres, observações a 250, CEP a 15 e telefone a 20; os editores do Mac (change 4) não limitam. A importação corta o excedente (a spec exige) e hoje avisa. Recomendo impor os limites nos editores, porque o AnthroPlus de Windows também corta ao importar. Não fiz porque mexe na tela de uma change arquivada.

## add-nutritional-survey (change 5, arquivada em 14/10/2026)

- **[proteção]** Arquivar o inquérito aberto com alterações pergunta antes se salva, como o `AskForSave` do original (D13).
- **[proteção]** Folha de edição aberta bloqueia a troca de módulo e o encerramento do app, também na Avaliação individual (D14, `AppModel.isEditingInSheet`).
- **[proteção]** O host de cada módulo registra o seu guarda de pendências ao aparecer; corrigiu um defeito latente da change 4.
- **[desvio]** Valor numérico inválido no editor de registro bloqueia salvar com aviso, em vez de virar vazio em silêncio (D11, política única das changes 3 a 6).
- **[forma]** Migração 3 com `DEFAULT` de data, lista ordenada sem diferenciar maiúsculas, XML de opções com valor ilegível rejeitado (D14).
- **[proteção]** Regra para a importação de inquéritos: registro com nascimento, data da pesquisa e idade em meses perde a idade digitada (D14).

## add-additional-data (change 6, arquivada em 14/10/2026)

- **[forma]** Datas do XML de dados adicionais pelo dia de calendário local e lidas ao meio-dia, com leitura estrita (D4).
- **[proteção]** Dados adicionais não alterados voltam com o XML original intacto, inclusive `nil` e XML ilegível; número gravado fora do limite não trava a edição do registro (D11).
- **[forma]** O modelo da visita nova é lido do banco a cada visita; se a leitura falhar, vale o modelo padrão do original (D12).
- **[forma]** Colunas dinâmicas na tabela só a partir do macOS 14.4 (D13; ver pergunta 1).
- **[proteção]** O escritor do XML descarta caracteres de controle colados (a quebra suave do Word tornava o registro ilegível), U+000B e U+000C como espaço (D14).
- **[desvio]** Escolher de novo o tipo já marcado não apaga os limites; confirmar a definição sem mudança marca pendência mas não regrava o texto (D14).
- **[forma]** Descrição da seção mostrada no formulário ("horas por semana"); "Gerenciar dados adicionais" como botão da barra; árvore do editor sempre expandida (D14).

## add-individual-import-export (change 7, arquivada em 15/10/2026)

- **[proteção]** Datas lidas num fuso fixo e convertidas ao meio-dia local: o dia de início do horário de verão (sem meia-noite em São Paulo) era recusado e rejeitava o arquivo inteiro (D17).
- **[desvio]** `Child` aninhado e `Mother`, `Father`, `Address` ou `Visit` fora de `Child` rejeitam o arquivo; o original anexava os avulsos à última criança lida (D17).
- **[desvio]** `DisplayID` acima de 2147483647 recusado, como o `int.Parse` do original (D17).
- **[proteção]** A importação avisa quantos textos foram cortados nos limites do original (sem contar `CreatedBy` e SALB, descartados); visita com dados adicionais ilegíveis interrompe a exportação com o nome da criança (D17).
- **[proteção]** Exportar a criança aberta com alterações pendentes pede para salvar antes; o relatório também (D17).
- **[forma]** XML com BOM, indentação e CRLF como o `XmlWriter` do original; rótulos do relatório no `AnthroIO` reexportados em `L10n.Exchange`; menu "Importar e exportar" na barra (D17).
- **[forma]** Cenário "Duas crianças marcadas em CSV" corrigido depois do vermelho: o cabeçalho tem as 7 colunas do modelo padrão de dados adicionais além das 43 fixas (Test Changes After Red).
