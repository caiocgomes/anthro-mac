# Achados de engenharia reversa: WHO AnthroPlus 1.0.4

Documento de referência para todas as changes em `openspec/changes/`. Cada achado é classificado como **observado** (lido no artefato), **inferido** (conclusão a partir de observações, ainda não verificada contra o original em execução) ou **desconhecido**. Os IDs `ev_*` são Evidence do REA da sessão de 14/10/2026, exportados em `docs/rea-evidence-bundle.json`.

## Artefato

| Item | Valor | Classe | Evidência |
|------|-------|--------|-----------|
| Instalador | `WHO_AnthroPlus_setup.exe`, PE32 x86, 2.630.314 bytes | observado | `open_binary`, SHA-256 `36d64400d5885b3dea9ea102e0f3f71e691271ecf004a1049b3ed1c40ea7175b` |
| Empacotamento | Inno Setup 5.3.10 (strings `Inno Setup Setup Data (5.3.10)`) | observado | `strings`; o grafo do REA não abre o payload Inno (`ev_2818ec5c7b4ef5e504423df4fadb7926de41f639abf05a69b60f2783a88949af`, "no child container entries") |
| Extração | `innoextract 1.9` para diretório isolado da sessão | observado | 21 arquivos em `app/`, ajuda em `app/Help/` |
| BLL | `WHOAnthroPlus.BLL.PC` 1.0.4.21881, CIL puro, metadados v2.0.50727, strong-name `316d92125cb992ee`, 69 tipos, 500 métodos | observado | `ev_23d0468366949aa1ff6ca13d6d342609bbd41da2cf05baa59428f7e292b718c9`, `ev_096236fe45bb666785b8602bce518be12d62b10f8359f0142980c9d44e77a4b4` |
| DAL | `WHOAnthroPlus.DAL.PC` 1.0.4.21880, referencia `System.Data.SqlServerCe` 9.0.242.0 | observado | `ev_5c248422229669e9db987d926892a5d88dd5c21ac5ceeb8aeb61c892d64f2caa` |
| UI | `WHO AnthroPlus.exe`, WinForms, gráficos com NPlot embutido; recursos es, fr, ru | observado | decompilação ILSpy 11.1 em `reference/decompiled/exe` |
| Banco | `WHOAnthroPlus.sdf`, SQL Server CE 3.0, conteúdo cifrado (strings sem estrutura), aberto com senha em `DBHelper.Init` | observado | `reference/decompiled/dal/WHOAnthroPlus.DAL/DBHelper.cs` |

O REA inventariou metadados, tipos, métodos, chamadas e acessos a campos sem executar código. A decompilação para C# foi feita com ILSpy, porque o provedor gerenciado do REA não decompila corpos de método.

## Algoritmo de cálculo (observado no código decompilado)

Fonte: `reference/decompiled/bll/WHOAnthroPlus.BLL.Core/AnthroComputation.cs` e `reference/decompiled/dal/WHOAnthroPlus.DAL.Reference/AnthroReferenceData.cs`.

- Idade em dias: `(int)(dataVisita - dataNascimento).TotalDays`; data de nascimento posterior à visita lança erro. Idade em meses: dias / 30.4375. Meses para dias: `Round(meses * 30.4375, 0)`, exceto 24 meses, que vira 731 dias.
- Faixa: idade em dias negativa ou `(int)meses > 228` dá `OffLimits` com todos os resultados indefinidos. Até 1856 dias, `Standards` (padrões 2006, busca por dia exato). Acima de 1856 dias, `Reference` (referência 2007, por mês). Sexo indefinido dá resultados indefinidos.
- Comprimento ou altura (só em `Standards`): abaixo de 731 dias é comprimento; medido em pé soma 0,7 cm. A partir de 731 dias é altura; medido deitado subtrai 0,7 cm. Em `Reference` a medida não é ajustada.
- IMC: peso / (cm / 100)^2 com `Math.Pow` em double; peso ou medida não positivos, ou IMC $\geq$ 1000, dão indefinido. Usa a medida ajustada.
- Peso para idade: indefinido com edema ou peso < 0,9 kg. Estatura para idade: indefinido com medida < 1. IMC para idade: indefinido com edema, peso $\leq$ 0 ou medida $\leq$ 0.
- Z-score LMS: $z = ((Y/M)^L - 1) / (L S)$. Com `L == 0` o código devolve $(Y/M)^0 = 1$ (ramo morto nas tabelas da OMS).
- Ajuste além de $\pm 3$ DP (`computeFinalZScore`, só peso e IMC): se $z < -3$, $z = -3 - (SD3neg - Y)/(SD2neg - SD3neg)$; se $z > 3$, $z = 3 + (Y - SD3)/(SD3 - SD2)$, com $SDk = M (1 + L S k)^{1/L}$. Estatura para idade não recebe ajuste.
- Percentil (`Centile`): aproximação de Abramowitz e Stegun com coeficientes **truncados** 0.31938, 0.356563782, 1.781477937, 1.82125, 1.330274429 e $1/\sqrt{2\pi}$; indefinido se $|z| > 3$ ou fora de [0, 100]. Calculado sobre o z não arredondado.
- Arredondamento: `sign(x) * floor(|x| * 10^p + 0.5) / 10^p`; z com 2 casas, percentil com 1, medidas com 2, IMC exibido com 1.
- Interpolação na referência: meses inteiros usam a linha do mês; meses fracionados interpolam L, M e S linearmente entre o mês inferior e o superior. Linha ausente torna o indicador indefinido.
- Plausibilidade (`IsFlaggedUsingDefault`): peso para idade fora de [-6, 5], estatura para idade fora de [-6, 6], IMC para idade fora de [-5, 5], ou z indefinido, marcam flag. Mesmos limites para padrões e referência. Ordem de `GetFlagUsingDefault`: peso e estatura juntos, peso, estatura, IMC.
- Cores de gravidade (`IndicatorDisplayPanel.SetZLabelColor`): $|z| < 1$ verde, $< 2$ dourado (Goldenrod), $< 3$ laranja-vermelho (OrangeRed), indefinido transparente, demais preto.
- Curvas: linhas de DP de -3 a +3 por $M (1 + L S k)^{1/L}$; percentis 3, 15, 50, 85 e 97 com $k$ = -1.88, -1.036, 0, 1.036, 1.88. Padrões amostrados a cada 4 dias; referência limitada a 120 meses (peso) e 228 meses (estatura e IMC).

## Divergências entre ajuda e código (observadas)

| Tema | Ajuda (`Help/*.htm`) | Código | Decisão |
|------|----------------------|--------|---------|
| Escolha deitado ou em pé | "0 a 60 meses" | habilitada só com idade < 11 meses; a partir disso força "em pé" (`ACMain`, `IAVisitDialog`, `NSRecordDialog`) | seguir o código |
| Cor de 2 a 3 DP | "vermelho" | `OrangeRed` | seguir o código |
| Data aproximada | "dia aleatório dentro do mês" | `Random.Next(1, DiasNoMês)`, limite superior exclusivo: nunca sorteia o último dia | seguir o código |
| Pontos de peso no gráfico | nada dito | `GraphDialog.cs:550` só desenha pontos de peso para idade com parte inteira dos meses $\leq$ 108 (constante `REF_UPPERAGELIMITMONTHS_W4A`), embora o z de peso seja calculado até 121 meses; afeta crianças de 9 a 10 anos da coorte da Suzan | seguir o código (registrado na change `add-anthropometric-calculator`) |

## Regra de 108 meses no peso para idade do inquérito (observado)

`AnthroAnalysis.ComputePrevalences` (linha 71) soma ao denominador (`PopCount`) todo registro de peso para idade com parte inteira dos meses acima de 108, sem levá-lo aos numeradores de prevalência nem à média. `Record.IsFlagged` (linha 516) trata esses registros como plausíveis. A ajuda diz que as estimativas usam "todas as crianças com z plausível". Efeito na coorte da Suzan (5 a 10 anos): na faixa de 9 anos e no total, prevalências e média de peso para idade ficam puxadas para zero. A change `add-survey-analysis` reproduz o original por fidelidade e pede confirmação da usuária na tarefa 0.4, antes do apply.

## Dados de referência

- **Inferido:** as tabelas `AnthroStd_*` (por dia) e `AnthroRef_*` (por mês) do `.sdf` equivalem às tabelas públicas da OMS. Base: (a) o limite de 1856 dias do código coincide com o último dia das tabelas expandidas da OMS; (b) as consultas de curva filtram `Age <= 120` e `Age <= 228`, o que só faz sentido se as tabelas forem além desses meses, como as do pacote R `anthroplus` (até 121 e 229).
- **Desconhecido:** igualdade linha a linha com o `.sdf`. Fechar exige rodar o original em Windows (VM ou CrossOver) e comparar saídas.
- O pacote R `anthro` vai só até 1826 dias; entre 1827 e 1856 dias a paridade usa as tabelas expandidas com o mesmo algoritmo, não o pacote R.
- **Observado na paridade (14/10/2026):** o pacote R `anthro` 1.1.0 trata medida em pé abaixo de 9 meses como implausível e não soma 0,7 cm; o AnthroPlus 1.0.4 soma. Fora desse caso, 600 de 600 casos de 0 a 5 anos e 600 de 600 de 5 a 19 anos dão z idênticos aos pacotes R (3.110 z-scores, diferença máxima 0). A identidade das tabelas embutidas com as da OMS usadas pelo R fica observada; com o `.sdf` original continua inferida.

## Modelo de dados do original (observado nas strings SQL do DAL)

- `Children`: DisplayID, FirstName, LastName, DateOfBirth, DateOfBirthIsApprox, Sex, MotherID, FatherID, AddressID, Notes, FollowUpDate, FollowUpInterval, FollowUpRefTo, IsArchived.
- `Visits`: ChildID, Date, Weight, Height, IsRecumbent, HasOedema, Notes, AdditionalData.
- `Mothers` e `Fathers`: FirstName, LastName, Height, Weight, DateOfBirth, DateOfBirthIsApprox, Notes.
- `Addresses`: StreetInfo, Place, ZIP, District, Province, State, Country, SALBLevel1, SALBLevel2, PhoneNumber, Email.
- `Surveys`: Name, Notes, AdditionalDataDef, Options, IsArchived.
- `Records`: SurveyID, Date, Cluster, Team, DisplayID, Household, WeightingFactor, FirstName, LastName, DateOfBirth, DateOfBirthIsApprox, Age, Sex, Weight, Height, IsRecumbent, HasOedema, Notes, AdditionalData.
- Todas as tabelas têm CreatedBy, LastUpdatedBy e LastUpdatedAt (multiusuário, fora de escopo).

## Ferramentas de verificação do REA

`build_reconstruction_obligation_ledger`, `evaluate_reconstruction_coverage` e `verify_reconstruction` exigem casos do original com autoridade `controlled-replay` ou observação em execução. Sem Windows, essa autoridade não existe nesta máquina. A verificação de paridade das changes usa os pacotes R da OMS como oráculo externo e registra isso como evidência mais fraca que um replay do binário.
