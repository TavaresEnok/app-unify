# ADR 0001: app Flutter dentro do monorepo

## Status

Aceito em 2026-07-10.

## Contexto

O projeto mantinha duas copias divergentes do mesmo app Flutter e configurava
`app-flutter/unified` como submodulo apontando para o mesmo remoto do repositorio
principal. Isso duplicava validacoes, causava conflitos de branch e permitia que
correcoes fossem aplicadas em apenas uma copia.

## Decisao

- `app-flutter/unified` e a unica fonte do app do assinante.
- O diretorio e versionado diretamente pelo monorepo, sem submodulo.
- O APK Builder, CI e scripts operacionais usam esse caminho.
- Nao devem existir `pubspec.yaml`, `lib/` ou plataformas Flutter na raiz.

## Consequencias

Builds e testes passam a usar uma unica arvore. Alteracoes no app e nos
contratos podem ser revisadas no mesmo commit dos servicos que as consomem.
