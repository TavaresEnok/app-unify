# Baseline da Refatoracao - 2026-07-10

Branch: `refactor/base-architecture`

Objetivo: registrar o estado tecnico antes de refatoracoes estruturais maiores.

## Git

Base inicial:

- `main` em `4e07baf Aplicar redesign do painel admin`.
- Branch criada: `refactor/base-architecture`.

Limpeza feita:

- Removidos do controle de versao, via `git rm --cached`, artefatos gerados e residuos:
  - `admin-painel/dist_final/`
  - `api-service/dist/`
  - `proxy-sgp/venv/`
  - `deploy_pid`
  - `Failed`
  - `Get`
  - `Run`

Observacao:

- Essa limpeza remove os arquivos do indice do Git, mas nao e uma remocao destrutiva de codigo fonte.
- Esses caminhos ja estao cobertos por `.gitignore` no `main`.

## Builds

### Painel admin

Comando:

```bash
npm run build --prefix admin-painel
```

Resultado:

- Passou.

Avisos:

- `baseline-browser-mapping` desatualizado.
- `caniuse-lite`/Browserslist desatualizado.
- Chunk principal maior que 500 kB (`index-olALRIUC.js`, cerca de 969 kB minificado).

### Firebase Functions

Comando:

```bash
npm run build --prefix functions
```

Resultado:

- Passou.

### API service

Comando:

```bash
npm run build --prefix api-service
```

Resultado:

- Passou.

## Testes

### Firebase Functions

Comando:

```bash
npm test --prefix functions
```

Resultado:

- Passou.
- 2 suites passaram.
- 32 testes passaram.

Aviso:

- `ts-jest` alerta que module kind hibrido `NodeNext` recomenda `isolatedModules: true`.

### Flutter analyze

Comando:

```bash
flutter analyze
```

Resultado:

- Falhou.
- 63 issues encontradas.

Erros principais registrados:

- `diagnostic_05_page.dart`: `final_not_initialized_constructor` em `valueColor`.
- `lib/core/painel_page.dart`: varios providers indefinidos, como `configurationProvider`, `authNotifierProvider`, `notificationProvider`, `analyticsServiceProvider`, `themeProvider`, `reviewServiceProvider`.
- `lib/core/services/test_history_service.dart`: `debugPrint` nao definido no contexto atual.

Tambem existem warnings/infos de:

- imports nao usados.
- campos nao usados.
- `withOpacity` deprecated.
- `print` em codigo de producao.
- `BuildContext` usado apos async gap.

### Flutter test

Comando:

```bash
flutter test
```

Resultado:

- Falhou porque o diretorio `test` nao existe.

## Docker

Comando:

```bash
docker compose ps
```

Resultado:

- `painel_api`: up/healthy em `8034`.
- `painel_frontend`: up/healthy em `8031`.
- `painel_proxy_sgp`: up/healthy em `8030`.
- `painel_postgres`: up/healthy.
- `painel_redis`: up/healthy.
- `painel_caddy`: up.
- `painel_landing`: up em `8032`.
- `painel_speedtest`: up em `8033`.
- `painel_apk_builder`: up em `8035`.

## Diff hygiene

Comando:

```bash
git diff --check
```

Resultado:

- Passou.

## Bloqueios antes de refatoracao funcional

1. Resolver ou classificar tipos de `function_requests` usados pelo front/app sem handler identificado.
2. Decidir como tratar o Flutter: corrigir baseline primeiro ou limitar refatoracao inicial ao painel/backends.
3. Adicionar testes/smoke tests do painel antes de mover services e rotas.
4. Definir schema canonico de `ProviderConfig` com compatibilidade para o app.
