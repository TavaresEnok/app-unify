# F1 C5/C6 — saída SGP e isolamento de credenciais

Data: 2026-10-31 UTC. Executor nominal: Codex, GPT-6.1 Sol, programador
delegado nesta worktree `task-2eda0f2a79ac-f1-sgp-outbound`.
Base efetiva `a499dea`; lote anterior `17baa3af4fe4`, implementação/correção
C4/C11/E3 `b5ab897`, agora revisado/integrado pelo controlador. Recibos herdados
preservados: 48 API, 87 Functions, 20 UI e builds finais aprovados. Esses
resultados não são execuções novas de C5/C6. Sem commit, push, merge ou deploy.

## Implementação e consumidores investigados

- API: `subscriber.routes` → `resolveSgpCredentials` → `createSgpSession`.
  Antes havia fallback global sem tenant e URL/app públicos; validação DNS
  precedia Axios, que podia resolver novamente e seguir redirects.
- Proxy: login `/check-cpf`, consumo, faturas, promessa, ONU e Wi-Fi usam
  `ensureSgpCredentials`/`callSgpApi`. Worker usa os mesmos exports para sync e
  lembretes. Antes havia inferência por CPF/`limit(1)`, fallback global mesmo
  após lookup falhar e validação incompleta de IP sem DNS.
- Functions `SGP_API_PROXY` autoriza tenant e exige integração privada completa
  antes de solicitar sync; envia somente tenant/segredo interno ao proxy, que
  relê a configuração. Status/cache não fazem saída SGP. Fetch interno nega
  redirect. API → proxy também desativa redirects/proxy por ambiente.
- Não existe consumidor de usuários autorizado a selecionar modo global.
  Nenhuma necessidade operacional global/privada foi demonstrada: modo global
  removido, sem exceção ampla; variáveis/segredo operacional não foram apagados.

`shared/runtime/sgp-outbound.js` é o runtime canônico, CommonJS para proxy;
cópia API `.ts` troca exclusivamente `module.exports =` por `export default`,
compilada pelo build TypeScript existente. Sync/check comparam essa transformação
determinística; Docker autônomo já copia fontes/lib e dist. Nenhuma dependência,
framework, serviço ou imagem foi trocada por conveniência.

O transporte usa Node HTTP/TLS diretamente: todos os resultados DNS devem ser
públicos, um endereço aprovado é fixado na conexão numérica e o socket somente
é entregue ao request após conferir o peer e autenticar TLS. Host/SNI e
verificação de certificado usam o hostname original. IPv4 normalizado e IPv6
global ordinário são classificados; mapped, tradução/transição e faixas
internas/especiais são negados conservadoramente. Userinfo, query/fragment de
entrada, caminhos com traversal/separadores codificados e opções de destino,
agent, proxy, headers/adapter são negados. Query GET é construída internamente.
Redirect nenhum é seguido, inclusive no mesmo origin. Proxies de ambiente não
são consultados. TLS é obrigatório também em test, sem switch de relaxamento.

Timeouts de request 30s API/60s proxy, limite DNS 5s, resposta 8 MiB e corpo
1 MiB; teto de sockets 128 total/16 por host no runtime. Cotas/cache/limites
existentes de upstream permanecem; testes injetam dependências explicitamente.
GET, form e JSON são preservados. Agentes por request são destruídos ao fim,
sem reutilizar conexão de resolução anterior.

Credenciais exigem tenant explícito e URL/token/app privados completos. CPF
compartilhado e token legado sem tenant não selecionam provedor. Payload de
usuário não substitui URL/token/app; wrappers conferem origin/prefixo e o proxy
confere token/app contra a integração. Integração SaaS mantém checagem de
revogação, conta/papel atual e autenticação recente; candidata insegura falha
antes da escrita, sem teste/transmissão ao SGP.

## Validação local

Ambiente: Node v24.22.1 disponível em `/home/app/.local/share/node24/bin`;
comandos executados da raiz da worktree com esse diretório no PATH. OpenSSL
local é usado somente para CA/chave sintéticas efêmeras dos testes TLS e
removidas ao final. Nenhuma credencial real, SGP, Firebase ou Redis produtivo
é necessário: Firestore, auth, cotas e conexões usam mocks/injeção explícitos.

Uma rodada essencial agrupada após o bloco funcional, seguida apenas de
repetições motivadas pela falha/correção e pelo fechamento de userinfo vazio:

| Comando | Status final | Resultado / execuções |
| --- | --- | --- |
| `npm --prefix api-service test` | exit 0 | 62/62, 9 arquivos; 3 execuções |
| `npm --prefix proxy-sgp test` | exit 0 | 24 aprovados, 6 skips, 30 totais; 3 execuções |
| `npm --prefix functions run test -- --run` | exit 0 | 89/89, 12 arquivos; 1 execução, resultado reutilizado após alterações exclusivas API/proxy |
| `node scripts/check-contracts.mjs` | exit 0 | cópias sincronizadas; 3 execuções |
| `node scripts/check-secrets.mjs` | exit 0 | 803 arquivos; 1 execução |
| `npm --prefix api-service run build` | exit 0 | TypeScript e empacotamento API; 3 execuções |

Primeira rodada API: 57 aprovados/5 falhas; proxy: 23 aprovados/1 falha/6 skips.
As falhas mostraram que `parseInt('')` ao classificar IPv6 comprimido gerava
`NaN` e passava comparações de intervalo. Adicionada exigência explícita de
número finito; casos `::`, `::1` e mapped já existentes permaneceram nos testes.
Segunda rodada API/proxy aprovada. Conferência final acrescentou rejeição de
userinfo vazio e sintaxe sem `//`, mantendo a regressão de nenhum socket aberto;
terceira rodada dos checks afetados aprovada. Functions/scan não foram repetidos
sem mudança relevante em seus escopos. Contagem: 14 invocações dos seis comandos
de validação/build; recibos anteriores não entram nessa contagem.

Os seis skips preexistentes do proxy exigem `REDIS_TEST_URL`: persistência de
fila, coalescência distribuída, concorrência por tenant, invalidação por mutação,
circuit breaker e reserva de capacidade de background. Redis real não foi
iniciado, e esses cenários não são apresentados como aprovados. Não foi chamado
benchmark Redis nem E2E por descoberta. Warnings não bloqueantes de npm
`store-dir`/carregamento futuro Vite e falta de segredo interno no mock proxy
não alteraram os resultados. Sem leitura de segredo operacional.

As regressões reutilizam cenários sobre ambas as cópias efetivas do transporte,
com servidor HTTP/TLS sintético. O conector injetado confere o IP numérico pedido
e representa esse peer no socket local; o teste negativo deixa o peer real
loopback e verifica que nenhum request chega. TLS real usa CA sintética,
SNI/hostname corretos, hostname errado e CA não confiável. Wrappers reais
exercitam A/B, integração incompleta/ausente, falha de lookup, tentativas de
forjar configuração, DNS misto/mutável e redirect. NODE_ENV=test mantém a política.

## Estado e gates

Código implementado e testes locais aprovados. Revisão independente
obrigatória pelo controlador é próxima fase, não aprovação do executor.
Não implantado, não distribuído; nenhum acesso a upstream/credencial real,
mudança de token, migração de banco/framework ou ação de host.

Integrações antigas que têm só token privado e URL/app públicos falham fechadas:
SaaS precisa reconciliar a integração privada completa em procedimento separado,
sem obter dados do backup de personalização. Nenhum documento real foi lido ou
alterado. Teste candidato/ativação versionada de Secret Manager permanece futuro.

Após revisão, ainda são necessários homologação dos artefatos Docker/API/proxy/
worker implantados em ambiente isolado, DNS/TLS da rede de destino autorizada,
jornadas de login/sync/faturas/ONU/Wi-Fi com tenants homologados, Redis/fila reais
em ambiente de teste e compatibilidade mobile/legados. Não são aprovações
simuladas. Regras reais/assets, revogação uniforme, builders/builds Android,
IAM/recuperação/custo e rotação E8 permanecem no backlog. C4/C11/E3/G0/G1 e
C5/C6 não encerrados integralmente. Não altera builder, locks ou outros domínios.

## Correção após primeira revisão independente — R1, R2 e R3

Atualização aditiva em 31/10/2026 UTC pelo executor **Codex — GPT-6.1 Sol**.
Os recibos e o estado acima descrevem a entrega anterior à revisão, preservada.
A primeira revisão independente do controlador **reprovou** essa entrega:
R1 (P1), rejeição de credenciais escapava das rotas ONU; R2 (P2), verificaacesso
do login não recebia providerId; R3 (P1), classificador aceitava IPv6 reservado.
As evidências sintéticas do revisor foram recebidas no contrato de correção;
não são reexecuções nem aprovação desta continuação.

- R1: ambas as rotas ONU retornam/encaminham a Promise ao Express; o try/catch
  agora inclui a resolução de credenciais. Regressão pelo servidor Express real
  verifica 400 para token/app/destino/sgpParams forjados e 503 para integração
  incompleta em ambas as rotas; nenhum request SGP e nenhuma unhandledRejection.
  O listener de observação existe somente no teste e é removido ao final.
- R2: verificaacesso recebe providerId já resolvido, sem adicionar token/app
  ao formato próprio de autenticação CPF/senha/contrato. Login HTTP real com
  A/B verifica chamada efetiva e respostas Online/Offline, form e credencial do
  tenant na consulta inicial. Emissão de custom token/perfil Firebase não é
  coberta nesse harness: auth é mock e a ausência de getUser produz o warning
  capturado pelo fluxo existente. Não equivale à homologação Firebase/mobile.
- R3: allowlist conservadora das alocações IPv6 ordinárias; intervalos não
  alocados/reservados e especiais falham fechados. Referência primária conferida:
  [IANA IPv6 Global Unicast](https://www.iana.org/assignments/ipv6-unicast-address-assignments/),
  registro atualizado em 10/10/2025. Novas alocações exigem revisão explícita da
  política, sem consulta dinâmica em produção. Cópias API/proxy sincronizadas
  pela transformação declarada e verificadas pelo check canônico.
  Casos literais e DNS misto incluem 2d00, 3000, 3ffe, demais blocos reservados,
  lacunas entre alocações e limites positivos. Nas duas cópias efetivas, HTTP
  e HTTPS negados não alcançam nenhum conector; cadastro SaaS também rejeita
  candidatos literais/mistos reservados sem persistir.

### Recibo novo desta correção

Mesma worktree/base `a499dea`, Node v24.22.1, diretório
`/home/app/.local/share/node24/bin` no PATH. Dependências explicitamente
simuladas e servidores HTTP/TLS sintéticos locais; nenhum serviço real usado.
Uma rodada agrupada após o bloco funcional completo; sem repetição de testes.

| Comando | Status | Resultado novo / execuções nesta correção |
| --- | --- | --- |
| `npm --prefix api-service test` | exit 0 | 69/69, 9 arquivos; 1 |
| `npm --prefix proxy-sgp test` | exit 0 | 25 aprovados/6 skips, 31 totais; 1 |
| `npm --prefix functions run test -- --run` | exit 0 | 89/89, 12 arquivos; 1 |
| `node scripts/check-contracts.mjs` | exit 0 | cópias canônicas coerentes; 1 |
| `node scripts/check-secrets.mjs` | exit 0 | 803 arquivos; 1 |
| `npm --prefix api-service run build` | exit 0 | TypeScript/empacotamento; 1 |

Seis novas invocações dos comandos essenciais/build; as 14 anteriores e os
recibos de `17baa3af4fe4` continuam históricos, sem recontá-los como execução
nova. Os seis skips Redis permanecem pendentes pelos motivos já descritos.
Warnings de configuração npm/Vite e mock de Firebase não são aprovação das
integrações ausentes. Nenhum benchmark, E2E, deploy, commit, migração ou troca
de segredo; token operacional privado intocado. Somente arquivos autorizados
na worktree foram alterados.

Implementação e checks essenciais concluídos; **nova revisão independente pelo
controlador pendente**, sem declarar R1–R3 aprovados pelo executor. Homologação
de rede/artefatos/fila, Firebase real em ambiente isolado, regras/mobile/assets,
compatibilidade legada, builds/revogação e E8 continuam nos gates/backlog acima.
C4/C11/E3/G0/G1 e C5/C6 não são encerrados integralmente por este recibo.
