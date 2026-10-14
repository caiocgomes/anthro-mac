# Proposal

## Why

O WHO AnthroPlus só existe para Windows, e a Suzan trabalha num Mac. Antes de portar qualquer módulo é preciso a fundação do app nativo: um pacote Swift que compila sem Xcode, um `.app` instalável, a janela com os três módulos do original e um banco local que não perde os dados da pesquisa (300 a 500 crianças) por causa de uma migração com defeito ou de um arquivo corrompido.

## What Changes

- Cria `Package.swift` com os seis targets do layout do projeto (`AnthroCore`, `AnthroStore`, `AnthroIO`, `AnthroAnalysis`, `AnthroFeatures`, `AnthroPlusApp`) e seus targets de teste.
- Cria `scripts/build-app.sh`, que monta `build/AnthroPlus.app` com `Info.plist`, ícone e assinatura ad-hoc, e opcionalmente instala em `/Applications`.
- Cria a janela principal SwiftUI: sidebar com Calculadora antropométrica, Avaliação individual e Inquérito nutricional, atalhos ⌘1 a ⌘3, seção ativa lembrada entre aberturas, painel Sobre com a atribuição à OMS.
- Centraliza as strings da interface em pt-BR e a formatação de números no padrão brasileiro (vírgula decimal, "N/D" para indefinido).
- Cria o banco SQLite em `~/Library/Application Support/AnthroPlus/` com migrações versionadas, checagem de integridade, backup automático a cada abertura (10 mais recentes), restauração do último backup e exportação de cópia.

## Capabilities

### New Capabilities
- `app-shell`: pacote, bundle `.app`, janela e navegação entre módulos, atalhos, configurações persistidas, textos pt-BR, formatação numérica e painel Sobre.
- `local-data-store`: local do banco, migrações, integridade, backups, restauração e exportação de cópia.

### Modified Capabilities
- Nenhuma.

## Impact

- Código novo em `Package.swift`, `Sources/*`, `Tests/*`, `scripts/build-app.sh`, `assets/AppIcon.iconset/`, `VERSION`, `.gitignore`.
- Usa só frameworks do sistema: SwiftUI, Swift Charts, Foundation, SQLite3. Nenhuma dependência externa.
- Cria arquivos no diretório do usuário (`~/Library/Application Support/AnthroPlus/`).
- Todas as changes seguintes dependem desta.
