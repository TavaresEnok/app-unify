# Abertura do painel e dashboard

Verificação em produção em 2026-10-29. Foram medidos os perfis SaaS e provedor em contextos Chromium novos, acessando `/painel/login` com sessão Firebase válida. Os valores incluem HTML/JS, restauração da sessão, painel e consulta dos dados. A senha não é submetida nessa comparação. A rede e o dispositivo do usuário podem produzir outros tempos.

## Causas encontradas e mudanças publicadas

- A leitura do dashboard gravava um pedido em `function_requests`, aguardava o trigger Cloud Functions e recebia a resposta por um listener Firestore. Agora as duas leituras usam a API HTTP autenticada (`/api/admin/dashboard/panel` e `/panel/providers/:providerId`). As outras operações da fila continuam compatíveis.
- As consultas são compartilhadas em `shared/runtime/dashboard.ts`, copiadas para API/Functions com checagem de sincronização. O gráfico global consulta até quatro provedores em paralelo. A API reúne leituras simultâneas e guarda o resultado por até dez segundos, separado por escopo. As permissões e o estado ativo da conta são consultados novamente antes de cada resposta, inclusive quando os dados estão em cache.
- A expressão de empacotamento `/react/` também selecionava `@tiptap/react`, incluindo o editor inteiro na entrada. Agora a regra identifica o nome exato do pacote. Os testes de navegação confirmam que editor, Firestore, Functions e Storage não carregam na tela de login.
- Auth foi separado da inicialização dos outros SDKs. O dashboard não inicializa Firestore/IndexedDB. Analytics não tinha consumidores no painel e sua inicialização automática foi removida do caminho de entrada.
- Datas de tickets aceitam tanto timestamps JSON da API quanto objetos Timestamp usados pelas consultas antigas.

## Resultado

| Perfil / execução | Antes: painel com dados | Depois: painel com dados |
|---|---:|---:|
| SaaS / primeira | 4.582 ms | 3.803 ms |
| SaaS / segunda | 3.834 ms | 1.829 ms |
| Provedor / primeira | 4.231 ms | 1.655 ms |
| Provedor / segunda | 3.228 ms | 1.712 ms |

A primeira medição após a publicação incluiu inicialização dos clientes/certificados/conexões da API recém-reiniciada. Ela está incluída no relatório: a média das quatro execuções caiu de 3.969 ms para 2.250 ms (aproximadamente 43%). As outras três execuções ficaram entre 1,6 e 1,8 segundo. Não se trata de garantia de latência para todas as redes.

Foi realizado também login real por email/senha em contas temporárias, removidas ao terminar. O formulário apareceu em 0,51–0,55 s. Do início da ação de clique automatizada até os dados, foram 2,76 s no SaaS e 2,26 s no provedor, incluindo autenticação e a espera automática do navegador pelo botão estar estável. As respostas dos dashboards foram HTTP 200 e não houve erros JavaScript. Esse teste não possui uma medição anterior equivalente e não deve ser comparado diretamente à tabela de sessões restauradas.

## Validação e reprodução

35 testes da API, 67 das Functions, 10 testes unitários do painel e 8 testes de navegação desktop/celular passaram. Os testes verificam recusa de assinante, recusa entre provedores, conta desativada/papel revogado mesmo com cache e repetição após falha sem armazenar o erro. As regras de acesso foram preservadas. O smoke em produção confirmou os endpoints diretos, a fila legada e as negativas de acesso de assinante.

- `scripts/diagnostics/measure-panel.cjs --super-email EMAIL_SAAS --provider-email EMAIL_PROVEDOR`: exige ADC e `SMOKE_BASE_URL` HTTPS; mede sessões válidas sem registrar tokens ou dados de clientes.
- `scripts/diagnostics/measure-login.cjs --provider ID`: exige os mesmos parâmetros de ambiente; cria duas contas Auth temporárias com permissões administrativas para exercitar o formulário real e as remove em `finally`. Não envia email nem altera assinantes.
- [Valores registrados](./dashboard-timing.json).


## Continuação — 2026-10-30

A demora após clicar em Entrar foi investigada novamente. A medição agora parte do evento `submit` no próprio navegador, excluindo a espera automática do Playwright para o botão estabilizar.

Foram encontradas e corrigidas outras causas:

- O formulário aplicava um `setTimeout` progressivo de até 16 segundos **antes** de enviar uma tentativa após falhas anteriores. Esse atraso foi removido. O bloqueio local após dez credenciais inválidas e as proteções do Firebase permanecem; falhas de rede e limitação do provedor Auth agora têm mensagens próprias e não contam como senha incorreta.
- A consulta começava depois da autenticação, navegação e importação do dashboard. Agora a UI é pré-carregada durante o preenchimento e a consulta começa assim que o papel autenticado é conhecido. A navegação e a consulta avançam em paralelo. A promessa é compartilhada por UID/escopo, expira rapidamente e é descartada ao sair; não existem consultas de dados antes da autenticação. O servidor continua verificando a conta e o papel atual em cada leitura.
- O Suspense da página não oculta mais o painel inteiro enquanto o conteúdo da rota carrega. O login segue diretamente ao dashboard adequado.
- Havia pressão de memória no servidor e páginas da API/proxy em swap. Foram aplicadas reservas suaves de memória e desativado swap nos serviços críticos deste projeto. Após a publicação, API e frontend apresentaram zero bytes em swap. Reservas suaves ajudam sob contenção, mas não criam RAM nem garantem capacidade ilimitada. A pressão geral causada por outros serviços ainda pode afetar o host.
- A API prepara a conexão Firestore e o dashboard global na inicialização; uma falha nessa preparação não bloqueia o processo e a consulta é repetida no acesso.

Resultado, da submissão até os dados reais:

| Perfil | Antes desta rodada | Depois |
|---|---:|---:|
| SaaS, primeiro acesso após reinício | 3.666 ms | 2.303 ms |
| Provedor | 1.814 ms | 1.618 ms |

A autenticação ainda envolve chamadas externas ao Firebase. Isso faz parte desses tempos; não há promessa de login instantâneo. A eliminação dos até 16 segundos de espera foi comprovada em teste separado: seis erros de credencial simulados, seguidos de sucesso, enviam a tentativa correta imediatamente. O mesmo teste confirma que o painel aparece durante uma resposta pendente e que apenas uma consulta de dados é feita. Os 10 testes desktop/celular, 14 testes unitários do painel e 37 testes da API passaram.

Também foi incluída medição do navegador autenticado: `POST /api/admin/performance` recebe somente o tipo de fluxo e os tempos numéricos total, autenticação e API. Não recebe email, UID, senha, URL ou dados de assinantes. O servidor deriva o papel do token e rejeita campos extras. Guarda no máximo 100 amostras em memória, visíveis por até 24 horas em `GET /api/admin/metrics`, exclusivo do SaaS admin; reiniciar a API limpa as amostras. O envio é assíncrono e não retarda a tela. Assim é possível distinguir a demora da sessão real da demora observada nos testes.

[Valores desta rodada](./login-followup-2026-10-30.json). [Semântica dos limites de memória e swap](https://docs.docker.com/engine/containers/resource_constraints/).
