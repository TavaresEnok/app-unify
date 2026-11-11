# Capacidade e operação em servidor único

Revisão: 2026-10-29. Meta de produto: 20 provedores com aproximadamente 5.000 assinantes cada. A quantidade cadastrada não determina acessos simultâneos; essa meta não é uma capacidade homologada.

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

O teste sintético de cache usa 20 provedores e SGP simulado. Ele prova reunião de chamadas e isolamento, não capacidade HTTP, latência de SGP real, nem 100 mil usuários simultâneos. Os testes também verificam fila após reconexão, retomada de progresso, circuit breaker, invalidação de cache e paginação de 5.000 registros.

Antes de aumentar a base, observar p95, 429/503, espera/falhas de jobs, memória/swap, disco, Redis e banda em carga representativa. Repetir o teste com distribuição realista de leituras novas e cache, vários contratos, SGP lento, pico após push e interrupção do worker.

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

## Medição HTTP em ambiente isolado

`REDIS_TEST_URL=redis://127.0.0.1:16379 npm run measure:capacity` usa a API Express real, assinaturas RSA e verificação por requisição, cotas/cache/coordenação no Redis de teste e SGP simulado por HTTP. O Firestore é substituído por dados em memória. Não cria usuários reais nem chama o SGP de produção. O relatório está em [capacity-report.json](./capacity-report.json).

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
