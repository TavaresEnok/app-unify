# Relatorio de analise do sistema

## Escopo
Analise estatica dos arquivos no repositorio `/home/app/painel-provedores-projeto`, sem executar o sistema e sem alteracoes de codigo.

Principais areas avaliadas:
- infraestrutura e deploy (Docker, scripts)
- seguranca (segredos, regras Firebase, exposicao de endpoints)
- consistencia de dados e integracoes (Firestore, SGP)
- manutencao e documentacao

## Principais achados (prioridade alta)

1) Segredos e credenciais no repositorio
- `api-service/src/config/serviceAccountKey.json` contem credencial do Firebase Admin. Isso e sensivel e nao deveria estar versionado.
- `.env` e `admin-painel/.env` contem chaves do Firebase (nao sao segredos por si, mas expostas e associadas a um projeto real).
- `proxy-sgp/index.js` contem `PROXY_SECRET_KEY` e token/app do SGP hardcoded.
- `api-service/src/index.ts` contem `FIREBASE_API_KEY` hardcoded e `SGP_TOKEN`/`SGP_APP_NAME` com fallback fixo.

2) TLS desabilitado em chamadas externas
- `api-service/src/index.ts` usa `https.Agent({ rejectUnauthorized: false })` em varias rotas. Isso permite MITM e quebra garantias de TLS.

3) Docker e deploy inconsistentes
- `docker-compose.yml` referencia `admin-painel/Dockerfile`, mas nao existe nenhum `Dockerfile` em `admin-painel/`.
- `api-service/Dockerfile` expõe `3000`, mas o servidor roda em `9136` (`api-service/src/index.ts`). O container pode iniciar sem porta correta exposta.

4) Inconsistencia de colecoes Firestore
- `functions/src/index.ts` mistura colecoes `provedores` e `providers`. Isso pode gerar dados duplicados ou inacessiveis para o app.

## Riscos e pontos de atencao (prioridade media)

1) Regras Firestore muito permissivas em areas criticas
- `firestore.rules` permite `clientes` com read/write para qualquer usuario autenticado. Pode expor dados entre provedores.
- `function_responses` permite leitura para qualquer usuario autenticado. Qualquer usuario pode ler respostas de outros, se souber o ID.

2) API exposta sem autenticacao forte
- Em `api-service/src/index.ts`, rotas como `/getClientData`, `/getConsumptionData`, `/getInvoices`, `/makePaymentPromise` nao exigem token do app (apenas CPF/senha). Se expostas publicamente, sao um alvo facil de abuso.
- `cors()` habilita qualquer origem, o que amplia a superficie de ataque (CORS aberto) no `api-service` e `proxy-sgp`.

3) Hardcodes de ambiente e URLs
- `api-service/src/index.ts` e `proxy-sgp/index.js` usam `https://vibetelecom.sgp.net.br` fixo. Isso dificulta multitenancy e ambientes de homologacao.

4) Cache e rate limit em memoria
- `proxy-sgp/index.js` usa cache e rate limit em memoria. Em mais de uma instancia, os limites nao se compartilham e a cache se perde em restart.

## Manutenibilidade e organizacao

1) Dependencias e artefatos versionados
- `node_modules/` aparece no repo em mais de um local (`/node_modules`, `api-service/node_modules`, `functions/node_modules`). Isso aumenta tamanho e dificulta deploy.
- `api-service/dist/` esta versionado. Isso geralmente deveria ser gerado no build.

2) Documentacao inconsistente
- `README.md` referencia arquivos que nao existem em `docs/` (`ARCHITECTURE.md`, `sgp-api.md`, `CODE_ANALYSIS.md`).
- `app-flutter/unified/README.md` e `app-flutter/admin_app/README.md` ainda sao o template padrao do Flutter, com pouca documentacao especifica.

3) Padroes e naming
- Mistura de idiomas e nomes (`provedores` vs `providers`) dificulta manutencao.
- Varias configuracoes repetidas (chaves Firebase em dois `.env`).

## Sugestoes de melhoria (acoes recomendadas)

Seguranca
- Remover credenciais do repositorio e mover para um gerenciador de segredos ou variaveis de ambiente.
- Substituir `rejectUnauthorized: false` por validacao TLS padrao e tratar certificados corretamente.
- Restringir CORS e proteger endpoints sensiveis com autenticacao mais forte (JWT/App token + rate limit por usuario).
- Revisar regras do Firestore para isolar dados por provedor/usuario (especialmente `clientes` e `function_responses`).

Infra/Deploy
- Corrigir `docker-compose.yml` para apontar para um Dockerfile existente, ou adicionar o `Dockerfile` faltante em `admin-painel/`.
- Ajustar porta exposta no `api-service/Dockerfile` para coincidir com a porta usada no app.
- Adicionar `.env.example` e documentar configuracao recomendada.

Consistencia de dados
- Padronizar colecoes (`provedores` vs `providers`) e garantir que painel, app e functions usem o mesmo nome.

Manutencao e qualidade
- Remover `node_modules` e `dist` do controle de versao; usar `.gitignore` e builds reproduziveis.
- Atualizar `README.md` e documentos em `docs/` para refletir a arquitetura real.
- Documentar integracoes SGP e fluxos principais do app (admin e cliente).

## Arquivos-chave revisados
- `README.md`
- `docker-compose.yml`
- `api-service/src/index.ts`
- `api-service/Dockerfile`
- `functions/src/index.ts`
- `firestore.rules`
- `storage.rules`
- `proxy-sgp/index.js`
- `.env`
- `admin-painel/.env`
- `app-flutter/unified/README.md`
- `app-flutter/admin_app/README.md`

