# Lessons

## 2026-10-14: relatório do portão vermelho sem explicar que a falha é intencional

- **Erro concreto:** ao parar na tarefa 0.4 da `bootstrap-macos-app`, apresentei "30 testes falham" em tabela, com trechos de falha, sem dizer em linguagem direta que falhar é o estado esperado nesse passo (o código ainda não existe) e que a parada é exigência do schema sdd-tdd, não um problema encontrado.
- **Correção do usuário (literal):** "eu não entendi pq erros falharam e vc me trouxe eles em vez de corrigir"
- **Regra:** todo relatório de portão vermelho abre com duas frases simples: (1) os testes falham de propósito, porque foram escritos antes do código, e é isso que prova que eles detectam a ausência do comportamento; (2) parei porque o schema pede aprovação antes de congelar os testes, e "corrigir" é exatamente a implementação que vem depois do OK.
- **Como aplicar:** em qualquer parada obrigatória de processo (portão vermelho, aprovação de spec, checkpoint), dizer primeiro por que parei e o que a aprovação libera; detalhe técnico (tabelas, trechos) vem depois e é opcional. Não usar "falha" sem qualificar como esperada quando ela é esperada.

## 2026-10-14: parar no vermelho em vez de seguir para o verde

- **Erro concreto:** depois de escrever os testes e stubs (vermelho), parei para pedir aprovação antes de implementar, tratando a parada como o resultado da sessão.
- **Correção do usuário (literal):** "sim, mas é como TDD manda. vc faz a casca em vermelho,e ai no verde faz o codigo até eles passarem"
- **Regra:** em `/opsx:apply`, vermelho e verde são uma sequência contínua: escrever testes e stubs, confirmar a falha por asserção, commitar o vermelho e seguir direto para o código até os testes passarem. O portão de aprovação só para de fato nas changes que fixam números clínicos (`port-anthro-engine` e `add-survey-analysis`), conforme a proposta aceita com "sim".
- **Como aplicar:** nas demais changes, registrar o vermelho no ledger, anunciar em uma linha que o portão foi registrado e seguir implementando no mesmo turno; reportar só no fim (ou num bloqueio real).
