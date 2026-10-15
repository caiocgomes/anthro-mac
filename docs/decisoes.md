# Decisões tomadas sem consulta

Registro das decisões que tomei sozinho durante a implementação das changes OpenSpec, para o Caio revisar quando quiser. Cada item diz o que foi decidido, por quê e onde está o detalhe. O registro formal de cada change continua no `design.md` dela (itens "Decisões tomadas na implementação"); aqui fica o índice legível.

Legenda: **[desvio]** muda um comportamento observável do original; **[proteção]** evita perda de dado; **[forma]** é escolha de implementação sem efeito nos números.

## Perguntas em aberto para o Caio

1. **Versão do macOS do Mac da Suzan.** A tabela do inquérito só mostra as colunas de dados adicionais a partir do macOS 14.4; o pacote declara 14.0. Mantive o alvo e escolho a tabela na view (D13 de `add-additional-data`). Se o Mac dela tiver 14.4 ou mais, subo o alvo e o ramo degradado some.
2. **Limite de tamanho nos editores da Avaliação individual e do Inquérito.** O original limita nomes e campos de endereço a 50 caracteres, observações a 250, CEP a 15 e telefone a 20, e no inquérito o nome a 50, nome e sobrenome do registro a 50 e notas a 250; os editores do Mac (changes 4 e 5) não limitam. A importação XML corta o excedente (a spec exige) e hoje avisa, nas duas telas. Recomendo impor os limites nos editores, porque o AnthroPlus de Windows também corta ao importar e a ida e volta pelo XML só fica exata assim. Não fiz porque mexe na tela de changes arquivadas.

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

## add-survey-import-export (change 8, arquivada em 15/10/2026)

- **[proteção]** Registros apagados em DBF continuam ignorados (pergunta aberta do design, decidida sem consulta): num arquivo de pesquisa, um registro apagado que reaparece é erro silencioso (D8, D18).
- **[desvio corrigido no plano]** Idade lida com as duas datas é descartada, na planilha e no XML, como o setter de `Record.Age` do original; o cenário de ida e volta que prometia "idade calculada" foi corrigido antes do vermelho (D18).
- **[proteção]** Lições da change 7 aplicadas ao XML de inquéritos: datas num fuso fixo, codecs aninhados decodificados depois da leitura, elementos fora do lugar recusados, caracteres de controle filtrados na escrita (D18).
- **[proteção]** O rascunho importado só substitui o inquérito aberto depois da pergunta de salvar, se houver alterações (D18).
- **[proteção]** O rascunho importado abre como alteração não salva: abrir outro inquérito, trocar de módulo ou fechar o app pergunta antes de descartá-lo. Se salvar o inquérito aberto falhar nessa pergunta, o rascunho é descartado e o aviso da importação some (D19, D20).
- **[forma]** A pergunta sobre o inquérito aberto vem quando o rascunho fica pronto, não antes do diálogo de arquivo como no original; a importação XML não pergunta, porque só grava e recarrega a lista (D19).
- **[desvio]** Conglomerado, equipe, ID e domicílio acima de 2147483647 são inválidos, como o `int.Parse` do original (D19).
- **[proteção]** Exportar com o inquérito aberto marcado e alterado pede para salvar antes, como na Avaliação individual (D19).
- **[forma]** Aviso de linhas descartadas no formato do original ("Detalhes: linha 3, campo 'Sex'. ..."); com linhas descartadas e campos inválidos, a frase dos campos vem depois, em vez de sumir como no original (D19).
- **[proteção]** Data com ano de dois dígitos (`01/04/21`, comum no LibreOffice e no Numbers) lida pela janela do .NET (00 a 29 viram 20xx); antes virava o ano 21, sem aviso. Dia impossível na forma curta (`29/02/21`) é inválido. Vale também para a importação de crianças. A janela do Windows pode ser 2029 ou 2049 conforme a configuração regional; só os anos 30 a 49 mudariam (D20).
- **[proteção]** REC e DBF malformados viram "formato inválido" em vez de derrubar o app; nome de campo idêntico a outro é recusado, como no original; nomes acentuados do DBF lidos em Latin-1; DBF do Visual FoxPro lido (D20).
- **[desvio]** Separador: o padrão da extensão vence quando aparece no cabeçalho, como no original; a detecção só entra quando o original leria o arquivo numa coluna só (D4, D20).
- **[proteção]** Aspas abertas até o fim do arquivo são "formato inválido" (engoliam os registros seguintes); linhas só de separadores (`;;;`, da área usada do Excel) são ignoradas (D20).
- **[proteção]** XML de inquéritos avisa os textos cortados nos limites do original (como o de crianças), recusa inquérito sem nome e informa quando o arquivo não tem nenhum inquérito (D20).
- **[risco conhecido]** Fiéis ao original e não alterados: booleanos só em inglês (edema `S` ou `T` vira inválido e então "sem edema", com o aviso genérico de campos inválidos); CSV em Mac Roman lido como Windows-1252; a "linha N" do aviso conta registros depois das linhas vazias ignoradas. Se a Suzan usar planilhas com "S/N" no edema, vale reabrir (D20).
- **[forma]** Arquivada com a spec sincronizada (`survey-data-exchange` criada), a mesma escolha das changes 5 a 7, sem perguntar.

## add-survey-analysis (change 9, em andamento desde 15/10/2026)

- **[forma]** `AnthroIO` passa a depender de `AnthroAnalysis`, porque os relatórios consomem o cálculo das prevalências (D16).
- **[forma]** O oráculo do IC por cluster (pacote R `survey` 4.5) deixa de fora os desenhos em que o próprio R não devolve limites finitos (2 clusters, t com 1 grau de liberdade); o arquivo gerado é idêntico em duas execuções (D16).
- **[forma]** Gráfico por sexo como o original: sexo sem z não forma série, e sem nenhuma série o gráfico mostra "(Sem dados)" (D16).
- **Parada obrigatória no vermelho** (tarefa 0.4): change de números clínicos; aguardando o Caio aprovar os testes e decidir a regra de peso para idade acima de 108 meses.

