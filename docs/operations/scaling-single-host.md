# Capacidade e operação em servidor único

Revisão: 2026-11-13 (America/Fortaleza). Referência de produto: **100 provedores com aproximadamente 5.000 clientes cada**, totalizando 500 mil cadastros. A quantidade cadastrada não determina acessos simultâneos; essa referência não é uma capacidade homologada. API e frontend de 12/11 foram validados e publicados, com ambos os serviços saudáveis. As medições de 29/10 abaixo são históricas; as evidências de navegador, carga e execução Android têm escopos distintos e estão vinculadas nesta revisão.

## Incremento publicado em 12/11

- Personalização do painel usa leitura e escrita HTTP autenticadas, mantendo schema e isolamento do provedor, sem fila Firestore nesse fluxo. A autoridade dos dados continua no Firestore.
- Equipe e chamados passam a usar cursor HTTP: 25 itens por padrão, máximo 100 e `nextCursor`. A interface mantém anterior/próxima e indica que busca/filtros abrangem somente a página atual. Chamados ordenam por `updatedAt` e ID; registros legados sem `updatedAt` precisam de inventário/reconciliação para entrar na listagem. Alterações concorrentes podem mudar a posição entre páginas; não há snapshot estável de toda a consulta.
- A listagem resumida de provedores projeta metadados; o dashboard consulta nomes e conta por provedor somente os seis gráficos exibidos, preservando as agregações globais. A lista de tenants ainda é lida integralmente; rotas legadas e mensagens de chamados ainda têm leituras sem paginação.
- O cliente web reúne leituras iguais e mantém no máximo 64 entradas, vinculadas ao objeto de sessão, por até 15 segundos; limpa o cache em trocas de sessão e escritas. Polling de provedores pausa na aba oculta. Comandos HTTP não são repetidos automaticamente, pois timeout não prova ausência de escrita.
- Configuração pública sanitizada tem cache por processo limitado a 500 chaves, reunião de consultas iguais e TTL de 30 segundos, com cache HTTP de até 30 segundos. Escritas HTTP de configuração invalidam a chave no processo atual. Outros processos/escritores dependem de expiração; os dois caches podem acumular atraso.
- Middlewares compartilham a verificação Auth somente dentro da mesma requisição e token. Cada requisição nova mantém `verifyIdToken(token, true)` e consulta do usuário atual. Revalidações explícitas durante operações sensíveis continuam usando `verifyFreshToken`; revogação durante download de anexo tem regressão local. Cache de dados não substitui autorização.

Validação local da rodada web: API 122 testes, painel 63 testes unitários, 30 E2E workspace desktop/mobile, dez E2E padrão e Functions 185 testes aprovados; builds TypeScript/Vite aprovados, lint sem erros e com três avisos preexistentes. Contratos, arquitetura, scan de segredos e whitespace também aprovados. Os índices das novas consultas paginadas foram conferidos por consultas reais em produção, sem alteração de índices ou regras. Esses testes não homologam dispositivos Flutter. A publicação web abrangeu somente API e frontend; Functions, Rules, proxy e APK não foram alterados em produção nessa rodada. A rodada mobile posterior está descrita abaixo.

## Publicação e medição de navegação — 12/11/2026

O [recibo sanitizado de produção](./web-performance-2026-11-12.json) registra imagens construídas da árvore modificada sobre `347f186`, com sufixo `performance-20261112`; não equivale a árvore limpa inteiramente reproduzível apenas pelo commit. API e frontend ficaram saudáveis. Foram preservadas as tags de retorno `painel_provedores-api-service:rollback-performance-20261112` e `painel_provedores-frontend:rollback-performance-20261112`; a entrega não fez migração de dados.

As amostras seguintes vieram do Chromium no servidor. A coluna de primeira abertura usa um contexto de navegador novo com a API já aquecida; os retornos ocorreram dentro do cache de sessão de 15 segundos.

| Tela | Primeira abertura | Retorno com cache |
| --- | ---: | ---: |
| Provedores | 0,808 s | 36 ms |
| Equipe | 0,792 s | 42 ms |
| Suporte | 0,799 s | 37 ms |
| Aparência | 0,802 s | 5 ms |

O primeiro login após publicar levou 3,748 s; outro contexto, com API aquecida, levou 2,722 s. **A meta de login permanece sem comprovação.** As APIs aquecidas ficaram aproximadamente entre 0,58 e 0,66 s nas amostras. Salvar configuração, do clique à confirmação, levou 0,839 s com HTTP 200 e cor preservada. As durações antigas de salvar mediam apenas a fila Firestore, portanto não são uma comparação equivalente de ponta a ponta.

Não houve erro JavaScript. No contexto novo, até Aparência o SDK Firestore não foi baixado; o módulo do builder é carregado quando sua tela é aberta. A base observada tinha um provedor, dois usuários, nenhum chamado e oito clientes: navegar nela não prova desempenho com 100 provedores e 500 mil clientes. As amostras não são percentis de carga sustentada nem medições no celular/rede do usuário. Migração de dados, compatibilidade Flutter e recuperação integral continuam pendentes; a capacidade de 500 mil cadastros segue não homologada.

## Rodada posterior: diagnósticos mobile e API

O código Flutter passou a preservar `/api` na composição de endpoints e usar `DiagnosticBinding` nos seis diagnósticos, Meu WiFi e ping para recriar serviços quando configuração, conta ou contrato mudam. WiFi reúne leituras simultâneas, protege a saída durante a operação e trata a exibição da senha. Os três estilos de menu usam o mesmo serviço de ping completo, com `DiagnosticPing`/`DiagnosticRuns` extraídos; scanner limita execução a dez segundos e permite cancelamento; gráficos mantêm até 120 amostras. Esses limites contêm trabalho e histórico no app, sem demonstrar capacidade agregada da plataforma.

Os seis seletores agora renderizam a mesma `shared_diagnostico_page.dart`, com estado, testes, ações e resultados comuns em `MeasurementCard`/`SpeedMeasurementCard`. Os outros cinco estilos são wrappers de aparência usando `LayoutTokens`; a composição está padronizada, sem garantia de equivalência visual pixel a pixel. Foram removidos valores simulados de RSSI, gateway, ONU e dispositivos e a suposição de WPA2 no serviço; campos não medidos aparecem indisponíveis. Rótulos ONU/traceroute existem no estado inicial sem fabricar resultado.

Diagnóstico completo e traceroute isolado compartilham `TracerouteService`. O runner da API usa `-q 1 -w 1`, prazo global de 25 segundos e preserva saltos parciais no timeout; erros de execução não viram sucesso. `reached` depende do IP de destino realmente observado e `origin=server` explicita que o trajeto começa no servidor. O resultado não mede a rota física da conexão do assinante.

API 125 testes e Flutter 61 testes aprovados, com análise de `lib` e `test/core` sem problemas e regressões para os seis seletores e encerramento de streams na troca de contrato. Traceroute autenticado em produção retornou cinco saltos reais, `reached=false` e origem no servidor. Imagens API e builder foram publicadas nesta rodada, e o APK final foi disponibilizado. Não houve aparelho via ADB. Validar permissões, troca de conta/contrato, saída/cancelamento, WiFi e resultados em aparelho físico continua pendente; testes locais e publicação da API não equivalem a essa homologação. Permanecem os limites de banco/SGP/host, migrações de dados e SDKs e ausência de homologação para 500 mil clientes.

A correção do proxy WiFi normaliza listas diretas e envelopes `data`/`wifis`, rejeitando erros e formatos inesperados. Ao atualizar sem nova senha, busca a credencial atual da rede exata no SGP e retorna 422 se estiver ausente/mascarada; falhas explícitas do upstream não viram sucesso. Recibo final: 37 testes aprovados com Redis real isolado (`REDIS_TEST_URL=redis://127.0.0.1:16380`), sem testes pulados, e sintaxe aprovada; o container temporário foi removido. A imagem proxy foi publicada e ficou saudável, assim como API e builder; tag de retorno `rollback-wifi-20261112`. Isso não comprova alteração WiFi em equipamento físico.

Preview adicional de 390 × 844 com fontes reais passou nos temas claro/escuro; seis testes de seletores e um de formatação passaram novamente, mantendo a suíte Flutter de 61 testes e análise limpa. `ThemeData` independente evita mistura de cores entre os temas. O preview é evidência de renderização em teste, sem homologação em aparelho.

### APK final Vibe Telecom

O [APK final](https://appisp.com.br/public_apks/f1/vibe/1794516378/7ab4b099-1b95-4138-9342-6649e5530506/app.apk) concluiu a geração; o download real retornou HTTP 200, com aproximadamente 30,8 MiB. Este é o artefato final desta rodada.

| Identificação | Valor verificado |
| --- | --- |
| Job | `7ab4b099-1b95-4138-9342-6649e5530506` |
| Pacote | `br.com.provedores.vibe` |
| Versão | `versionCode=1794516378`; `versionName=1.0.1794516378` |
| Android / ABI | `minSDK=26`; `targetSDK=36`; arm64 |
| APK SHA-256 | `6d7e053922d1cee4e0a4afa3666824a54d6b5b2a267e5322b18f5d08d50be94a` |
| Certificado SHA-256 | `3f0b63d7a55a7303b877ed7a3fbbcecde241d65342f8feea5fb3df0bacedde45` |
| Fonte Dart `lib` SHA-256 | `a34cc6d8a51b466c9a5885c52a6c0cf5515c496db1add7221cc597bba1858f82` |

`apksigner verify` passou e o certificado corresponde ao do artefato anterior. A fonte congelada coincidiu entre host e imagem builder; seu hash usa caminhos relativos ordenados e os bytes dos arquivos Dart em `lib`. Disponibilidade, assinatura e identidade verificadas não comprovam instalação/atualização em aparelho físico, funcionamento de WiFi/ping ou capacidade para 500 mil clientes.

## Execução Android parcial — 13/11/2026

O [resultado sanitizado](../../test-results/android-runtime-2026-11-13/result.json) registra execução no AVD `painel_vibe_test`: Android 11 Google APIs x86_64 com KVM, usando SDK de teste em `/home/app/.cache/painel-android-test-sdk`. O APK release `1.0.1794516378` instalou, mas sua execução foi inconclusiva por `SIGILL` em `libndk_translation.so` durante tradução ARM para x86. Esse resultado não permite concluir defeito do app nem execução bem-sucedida do release.

Um build debug x86_64 privado da mesma fonte, com Flutter 3.44.0 em container, executou onboarding e tela de login com configuração pública carregada da API de produção. Foram corrigidos o contraste do campo de identificação e a barra de status em tema escuro: campo sem preenchimento indevido, preenchimento da senha por token de tema, controle mostrar/ocultar e overlay de sistema. A alternância de senha foi exercitada na UI Android, mudando o atributo de ocultação de verdadeiro para falso. A [captura corrigida](../../test-results/android-runtime-2026-11-13/login-corrected.png) não contém identificação de cliente.

O bootstrap de Auth anônimo anterior a `runApp` falhava com `admin-restricted-operation`; sua função, chamada e import foram removidos de `main.dart`, pois a configuração pública HTTP não exige Auth. O erro ficou ausente no log posterior à correção. Passaram 62 testes Flutter e a análise dos arquivos alterados ficou sem problemas. Essas correções existem somente na fonte e no build debug privado; o APK release público de 12/11 permanece sem atualização.

Entrada sem senha foi bloqueada pela UI; `/api/check-cpf` real respondeu 401 para senha vazia, mantendo os campos obrigatórios. A autenticação do servidor não foi alterada. A decisão sobre primeiro acesso validado ou mudança da jornada de contas sem senha permanece pendente; não há implementação de acesso somente por identificação. Diagnósticos autenticados ficaram sem execução nessa rodada e rádio WiFi não foi testado. A execução em emulador não homologa aparelho físico, atualização do release ou capacidade para 500 mil clientes; as migrações de dados e SDKs continuam pendentes.

## Controles implementados

- Administradores exigem `role=providerAdmin` ou `superAdmin=true`. `providerId` é apenas vínculo com empresa.
- Assinantes exigem senha central do SGP e recebem `role=subscriber`, `providerId`, `cpfCnpj`; UID `subscriber:{providerId}:{cpf}`. Tokens antigos sem papel explícito deixam de autorizar operações protegidas. O APK novo deve ser disponibilizado antes de ativar o backend.
- Perfis legados de mesmo provedor são migrados no login, com backup; CPF igual em provedores diferentes não compartilha a conta.
- Regras de Firestore/Storage e Functions verificam papel e provedor. Fila administrativa não aceita ações administrativas de assinantes.
- Configurações públicas não recebem credenciais de integração, inclusive em campos aninhados. `scripts/migrations/private-provider-credentials.cjs` remove cópias legadas de `integrations`, `config.integrations` e `details.apiToken`, com backup privado transacional; preserva a credencial privada já usada pelo backend. Como o token antigo esteve público, sua revogação e substituição no SGP continua necessária.
- Dashboards usam `count()`; listagens de clientes usam cursor, projeção de campos e até 50 itens. Respostas das Functions têm proteção de 700 KB.
- Cotas da API usam Redis e identidade autenticada. Login tem proteção por IP e identidade de login. O proxy verifica o token antes de atribuir a cota individual; tráfego da fachada não é agrupado pelo IP do container.
- O runtime em `shared/runtime/upstream.js` é sincronizado com API/proxy: limite compartilhado de 4 chamadas por provedor e 8 por host SGP (tarefas em segundo plano param em 2/4, reservando capacidade para acessos interativos), cache de leitura, reunião de chamadas idênticas e circuito de proteção após falhas. Alterações invalidam o cache; comandos não são repetidos automaticamente.
- Cache de dados usa Redis volátil, com eviction; cotas, coordenação e BullMQ usam Redis persistente separado com `noeviction` e AOF `everysec`.
- Sincronização e lembretes usam BullMQ: páginas limitadas, progresso persistido, tentativas com backoff e recuperação de trabalhos interrompidos. Credenciais e senhas não entram nos jobs.
- Lembretes são agendados às 09:00 de America/Fortaleza. Envio é **pelo menos uma vez**: falha após o FCM aceitar uma mensagem e antes de registrar a conclusão pode duplicar a entrega; FCM não fornece transação com a fila.
- PostgreSQL usa cache compartilhado com chave `(provider_id, client_id)`, sem nomes de tabela derivados do ID de empresa.
- Geração Android continua limitada a um build por vez; histórico em disco registra interrupções. CPU limitada a 2 com prioridade reduzida, RAM a 3 GiB, Gradle com heap de 1,5 GiB e até dois workers.
- Speed test usa orçamento global de banda, limite de conexões e duração. `/speedtest/capabilities` publica os limites; o app informa que o servidor compartilhado não comprova a velocidade total do plano. O padrão é até 300 Mbps agregados, sujeito à banda real do host.
- API: `/ready` verifica coordenação; `/admin/metrics` exige superAdmin e apresenta erros e p95 recente por rota. Worker possui healthcheck com estado da fila.

## Implantação

Sequência de referência da implantação anterior, com escopo maior que a publicação API/frontend de 12/11. Antes de outra implantação, confirmar versões suportadas, compatibilidade de Rules/envelopes RPC, manifesto dos artefatos e retorno seguro conforme o plano de rearquitetura. Não reaplicar migrações administrativas ou remover consumidores sem inventário atual.

1. Executar validações e `bash scripts/ops/backup-data.sh`.
2. Disponibilizar APK com senha. O build usa `app-flutter/unified`.
3. Aplicar papéis apenas às contas administrativas já verificadas. `scripts/migrations/explicit-admin-roles.cjs` é dry-run por padrão, exige os emails e não promove usuários apenas por `providerId`.
4. Publicar índices e colocar a criação de `function_requests` em manutenção temporária. Publicar as Functions novas e remover os 13 consumidores legados da mesma fila, preservando as callables; só então reabrir a fila com as regras finais. `PROXY_URL` usa HTTPS. Publicar painel e containers compatíveis na mesma manutenção.
5. Subir `redis-state`, API, proxy e `jobs-worker`; verificar `/ready`, fila e acessos de ambos os perfis. As credenciais SGP continuam exclusivamente nos documentos privados.
6. Testar uma sincronização e a paginação. Não executar cargas contra SGP de produção sem janela acordada.

## Validação reproduzível

```bash
NPM_CONFIG_USERCONFIG=/dev/null npm run validate:web
npm run validate:e2e
npm run validate:flutter
npm run test:rules
npm run test:ops
# Redis isolado de teste, nunca o Redis de produção:
REDIS_TEST_URL=redis://127.0.0.1:16379 npm test --prefix proxy-sgp
REDIS_TEST_URL=redis://127.0.0.1:16379 npm run measure:load
```

O teste sintético de cache (`measure:load`) usa SGP simulado; ele verifica reunião de chamadas e isolamento. O benchmark HTTP (`measure:capacity`) agora usa 100 provedores e um **espaço gerado de 500 mil identidades possíveis**, sem popular um banco com 500 mil clientes. Somente as identidades acessadas geram tokens/fixtures. Nenhum desses testes representa 500 mil acessos simultâneos ou capacidade de produção. Os testes também verificam fila após reconexão, retomada de progresso, circuit breaker, invalidação de cache e paginação de 5.000 registros.

Antes de aumentar a base, observar p95, 429/503, espera/falhas de jobs, memória/swap, disco, Redis e banda em carga representativa. Repetir o teste com distribuição realista de leituras novas e cache, vários contratos, SGP lento, pico após push e interrupção do worker.

## Critérios para homologar a referência de 100 provedores

Os critérios seguintes são **metas para ensaio e aceite**, ainda não comprovadas. Derivam da seção 8 do [plano](../plano-rearquitetura-2026-10-30.md), cujo cenário inicial de 20 tenants é histórico; a referência desta revisão é 100. Nenhum teste unitário ou pool de identidades substitui esse aceite.

| Critério | Evidência exigida antes de ampliar |
| --- | --- |
| Volume e escopo | Registrar 100 tenants e 5 mil clientes por tenant em base de teste representativa, tamanhos de documentos, contratos e distribuição desigual; separar cardinalidade, usuários virtuais, requisições simultâneas e RPS |
| Latência e sucesso | Medir por rota/jornada e status; meta inicial de leitura local/dashboard p95 ≤ 300 ms (dashboard p99 ≤ 800 ms) e sucesso das jornadas ≥ 99,5% no patamar aceito; publicar 429/503 e falhas de dependência separadamente |
| Web e app | Perfis de rede/dispositivo declarados; restauração até dados essenciais p95 ≤ 1,5 s e login p95 ≤ 2,5 s como metas; versões suportadas, erros e dados ausentes visíveis, sem confundir HTTP com tempo total da tela |
| Isolamento e autoridade | Zero acesso/dado cruzado, inclusive CPF igual em tenants diferentes; nenhum segredo público; revogação e papéis atuais conferidos sem cache de autorização entre requisições |
| Upstream | Registrar máximos por tenant e host, não apenas média global; respeitar 4/8 chamadas interativas e reserva 2/4 de background, reunir cache e comprovar recuperação após circuito aberto |
| Fila e frescor | Medir espera, idade, falhas, retries e retomada; hipótese inicial de sync p95 ≤ 15 min por tenant e configuração publicada disponível em até 60 s; testar perda/reinício, efeitos inconclusivos e ausência de replay indevido |
| Recursos | CPU/RAM/PSI/swap, disco/inodes/I/O, Redis, conexões PostgreSQL e banda registrados com folga acordada para SO e outras aplicações; ausência de OOM, crescimento ilimitado e perda de estado |

Executar degraus de 25, 50, 100 e 200 usuários virtuais com jornadas e janela definidas; não tratá-los como concorrência HTTP equivalente. Incluir cache frio/quente, SGP de 50/500/2.000 ms ou indisponível, respostas grandes, concentração em um tenant/host, rajada pós-push e sincronização concorrente. Medir também com build ativo e speed test, registrando a redução de capacidade. A janela, quantidade de amostras e margem precisam constar do relatório; o maior patamar que cumprir todos os critérios é o único candidato a homologação. Recusas controladas acima dele registram limite, sem virar sucesso do produto.

O relatório deve identificar commit, ambiente e limites, gerador de carga, latência Auth/Firestore/SGP, cache, RPS, percentis por status, chamadas upstream, fila e recursos. Separar assinatura de tokens do trecho cronometrado e registrar atraso do event loop quando API, mocks e gerador compartilham o processo. Primeiro usar ambiente isolado; carga pesada em SGP real exige janela e cotas específicas.

## Migrações e limites ainda pendentes

O incremento HTTP não conclui o monólito modular/PostgreSQL/outbox do plano. Firestore continua autoridade dos dados próprios e do RPC residual; PostgreSQL é principalmente cache SGP. Sincronização ainda grava os bancos independentemente, sem transação distribuída. Paginação nova não remove rotas legadas, SDKs diretos nem todos os scans/listeners.

Antes de cortar legado, concluir inventário por versão/tenant, compatibilidade Flutter/web, regras e revogação de todos os caminhos, escritor único por domínio, migração retomável e reconciliação. PITR com WAL externo, reconstrução integral de agendas após perda de Redis e recuperação conjunta de Firestore/Auth/objetos ainda exigem ensaio. RPO de cinco minutos/RTO lógico de quatro horas do plano são objetivos futuros, não garantias atuais. A referência de 500 mil cadastros não libera os gates G0/G1/G2 nem a troca de autoridade de dados.

## Limites que continuam existindo

Docker e limites de recursos não fornecem alta disponibilidade física. Falha do servidor, disco ou link ainda pode indisponibilizar todos os provedores. O backup PostgreSQL fica fora do repositório e foi criado para rollback; uma cópia apenas no mesmo servidor não protege contra perda da máquina. AOF `everysec` pode perder aproximadamente o último segundo em queda abrupta.

O backup automático está instalado como `painel-backup.timer`: todos os dias às **03h de America/Fortaleza**, com atraso aleatório de até cinco minutos, execução após reinício quando houver horário perdido e até três tentativas em caso de falha. CPU limitada a 50%, memória a 512 MiB e prioridade reduzida. Mantém sete dias localmente e trinta dias no bucket privado `backend_backups/runs/`, preservando pelo menos os três últimos conjuntos completos no bucket. A retenção só roda depois de um novo backup bem-sucedido e não altera snapshots antigos de implantação fora desse prefixo.

Cada conjunto inclui PostgreSQL, snapshot Redis da fila, APKs, estado dos builds, código-fonte disponível e configurações privadas/assinatura, usuários Auth com hashes e configuração de hash, e exportação gerenciada do Firestore. O Firestore exporta dados de negócio diariamente, incluindo coleções aninhadas de clientes, credenciais privadas e mensagens; aos domingos exporta tudo. O histórico de `function_requests`, `function_responses`, locks e auditoria entra na exportação semanal. Existem mais de 1,1 milhão de documentos históricos nessas duas primeiras coleções; eles não foram apagados. Exportar o Firestore consome uma leitura por documento, portanto a separação evita repetir esse custo todo dia.

Antes de enviar os arquivos, cada execução restaura PostgreSQL em um banco temporário e remove esse banco, verifica o RDB com `redis-check-rdb` e confere os arquivos compactados. Uploads verificam CRC32C e o manifesto registra SHA-256. O conjunto só recebe manifesto de conclusão depois da exportação Firestore terminar e dos uploads concluírem. Os backups contêm segredos: diretórios locais são privados, e os objetos não têm tokens públicos de download. O PostgreSQL foi restaurado e o Redis validado; não foi realizado um ensaio completo de importação Firestore/Auth em outro projeto. Os snapshots dos vários serviços não formam uma transação única.

Verificação e operação:

```bash
systemctl status painel-backup.timer
journalctl -u painel-backup.service
node scripts/ops/backup-status.cjs
sudo systemctl start painel-backup.service
# Recuperação/checagem local sem tocar nas tabelas de produção:
bash scripts/ops/verify-backup.sh /caminho/privado/do/conjunto
```

`services.sh health` também falha se não houver backup concluído nas últimas 26 horas. Não envia mensagens externas. A restauração real de Firestore/Auth exige seguir os procedimentos oficiais de importação, usando o manifesto, `auth-users.json` e `auth-config.json`; não executar importação sobre produção para testar. Backups ajudam a recuperar dados, mas não substituem outro servidor. Quando houver outro host, `APK_BUILDER_UPSTREAM` e `SPEED_TEST_UPSTREAM` permitem mover esses serviços; também será necessário configurar distribuição dos APKs e TLS/rede entre hosts.

## Referências

- [Paginação por cursor no Firestore](https://firebase.google.com/docs/firestore/query-data/query-cursors)
- [Limites de documentos](https://firebase.google.com/docs/firestore/quotas)
- [Cotas compartilhadas com Redis](https://github.com/express-rate-limit/rate-limit-redis)
- [Exportação e importação Firestore](https://cloud.google.com/firestore/native/docs/manage-data/export-import)
- [Exportação e importação Auth](https://firebase.google.com/docs/cli/auth)
- [Migração de Jest para Vitest](https://vitest.dev/guide/migration/)

## Auditoria de dependências

A suíte de Functions foi migrada de Jest/ts-jest para Vitest 4, já usado no projeto. Jest 30 também depende de `deepmerge` vulnerável, portanto apenas atualizar Jest não eliminaria [GHSA-gcqx-w48m-w2h4](https://github.com/advisories/GHSA-gcqx-w48m-w2h4). A dependência e sua cadeia foram removidas; os testes e os limites de cobertura foram preservados. O gate em `scripts/check-dependency-audit.mjs` agora rejeita qualquer advisory reportado e não contém exceções. Os seis componentes ficaram sem vulnerabilidades reportadas pelo npm audit na validação de 2026-10-29.

## Medição HTTP controlada — 12/11/2026

O [relatório desta rodada](./capacity-100-providers-2026-11-12.json) usa API Express real, assinatura/verificação RSA, Redis e SGP HTTP simulado, com **100 provedores e espaço gerado de 500 mil identidades**. Não contém um banco povoado com 500 mil clientes. Firestore e autoridade Auth são fixtures; cada requisição inclui duas consultas Auth simuladas, de 275 ms cada, mantendo a checagem de revogação e usuário atual. A assinatura de tokens ocorre antes do trecho cronometrado; API, mocks e gerador compartilham o processo, com atraso do event loop registrado. Esta execução controlada substitui a rodada exploratória com assinatura durante a medição e E2E concorrente como referência deste ensaio.

| Cenário | Requisições | Simultâneas | Resultado | p95 |
| --- | ---: | ---: | --- | ---: |
| Leituras repetidas com cache | 2.000 | 100 | 2.000 HTTP 200; zero chamadas adicionais ao SGP | 633,67 ms |
| Assinantes distintos sem cache; SGP 50 ms | 1.000 | 100 | 1.000 HTTP 200 | 867,54 ms |
| SGP lento, 500 ms | 400 | 100 | 400 HTTP 200 | 1.683,53 ms |
| Sobrecarga concentrada em dez tenants; SGP 500 ms | 1.000 | 200 | 120 HTTP 200; 880 HTTP 503 | 1.706,11 ms para 200; 815,05 ms para 503 |

O pico foi de quatro chamadas SGP simultâneas por tenant, sem divergências de isolamento nas fixtures, inclusive com CPF igual em tenants diferentes. O limite individual registrou 120 respostas 200 e cinco 429; a identidade vizinha continuou autorizada. Os 503 representam trabalho recusado para proteger o upstream: **o cenário concentrado não foi atendido integralmente**. Os percentis por status evitam apresentar a recusa rápida como sucesso da jornada.

Esses números não homologam a referência de produto nem os critérios de dashboard/leituras locais acima: o endpoint ensaiado consulta dados SGP, a base é simulada e não há janela sustentada de jornadas completas. Faltam Firestore/Auth/SGP reais, TLS de entrada, dispositivos Flutter, volume armazenado de 500 mil clientes e concorrência com worker/build/speed test e outros serviços do host. Nenhuma carga artificial foi aplicada a provedores reais. Não comparar diretamente com a medição de 29/10: quantidade de tenants, autoridade Auth, concorrência e concentração de carga mudaram.

## Medição HTTP histórica em ambiente isolado — 29/10/2026

O relatório histórico em [capacity-report.json](./capacity-report.json) foi produzido com API Express real, assinaturas RSA e verificação por requisição, cotas/cache/coordenação no Redis de teste e SGP simulado por HTTP. O Firestore foi substituído por dados em memória. Não foram criados usuários reais nem consultado o SGP de produção. A versão atual do comando `REDIS_TEST_URL=redis://127.0.0.1:16379 npm run measure:capacity` tem fixture de 100 provedores e autoridade Auth simulada; não reproduz literalmente o cenário histórico de 20 provedores.

A execução registrada usou Node 22 e um container com 1 CPU/768 MiB compartilhado entre API, gerador de carga, SGP simulado e Vitest. O pool contém 100 mil identidades sintéticas de 20 provedores; isso não significa 100 mil usuários simultâneos. Resultados:

| Cenário | Requisições | Simultâneas | Resultado | p95 |
|---|---:|---:|---|---:|
| Leituras repetidas com cache | 2.000 | 100 | 2.000 HTTP 200; nenhuma chamada adicional ao SGP | 996 ms |
| Assinantes distintos, sem cache; SGP 50 ms | 1.000 | 20 | 1.000 HTTP 200 | 603 ms |
| SGP lento, 500 ms por chamada | 400 | 40 | 400 HTTP 200 | 1.484 ms |
| Sobrecarga com SGP lento | 1.000 | 200 | 435 HTTP 200; 565 HTTP 503 de proteção | 4.629 ms |

Não houve mistura de dados entre provedores. O limite individual permitiu 120 chamadas e recusou as cinco seguintes com 429; outro usuário permaneceu autorizado. O máximo observado foi de quatro chamadas SGP simultâneas por provedor. **Há limite real:** um pico de 200 consultas sem cache contra SGP lento recebe recusas; este cenário não é atendido integralmente pela configuração atual. A fila/cache protegem o serviço, mas não criam capacidade no SGP.

Esses números não certificam produção: faltam latência/cotas do Firestore real, comportamento dos SGPs reais, TLS de entrada, dispositivos e concorrência com builds/outros sistemas do servidor. O teste agora é reproduzível e integra o CI; nenhuma carga artificial foi aplicada aos provedores reais.

## Verificação em produção

`scripts/diagnostics/smoke-production.cjs` exige ADC, `SMOKE_BASE_URL` HTTPS e emails administrativos explícitos. Faz consultas sem alterações de clientes; `--security-probe` cria e remove um usuário Auth temporário para confirmar negativas de acesso. `--sync` é opt-in: consulta o SGP real e atualiza o cache do provedor, sem enviar mensagens nem realizar pagamentos. Não usar para gerar carga artificial em produção.

Na implantação de 2026-10-29, a sincronização real concluiu com 399 registros retornados pelo SGP usando `limit`/`offset`; o endpoint ignora `pagina`. A proteção contra páginas repetidas evita laços e custos indefinidos. O cache histórico contém outros registros e não é apagado automaticamente quando um cliente deixa de aparecer na consulta de contratos ativos. O backup PostgreSQL posterior à sincronização foi enviado ao bucket privado e restaurado em um banco temporário, conferindo 492 linhas. Os três perfis passaram na navegação autenticada pelo Chromium; assinante permanece no formulário sem acesso administrativo.
