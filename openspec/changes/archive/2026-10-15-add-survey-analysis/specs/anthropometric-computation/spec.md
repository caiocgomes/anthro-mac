# Spec Delta

## MODIFIED Requirements

### Requirement: Arredondamento clínico
O sistema SHALL arredondar valores exibidos como `AnthroComputation.Round` do original, $\mathrm{sign}(x) \cdot |\lfloor x \cdot 10^p + 0.5 \rfloor| / 10^p$: o piso age sobre o valor com sinal, então o empate positivo vai para longe de zero e o negativo vai para zero; `nil` SHALL permanecer `nil`.

#### Scenario: Empates longe de zero
- **WHEN** o sistema arredonda 2.345 e 0.125 a 2 casas
- **THEN** os resultados são 2.35 e 0.13

#### Scenario: Empate negativo vai para zero
- **WHEN** o sistema arredonda -2.345 a 2 casas e -1.235 a 2 casas
- **THEN** os resultados são -2.34 e -1.23

#### Scenario: Valor indefinido
- **WHEN** o sistema arredonda `nil`
- **THEN** o resultado é `nil`
