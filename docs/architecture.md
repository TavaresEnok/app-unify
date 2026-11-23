# Arquitetura do Sistema Unify

Atualizado em 2026-11-13 (America/Fortaleza). Referência de produto: **100
provedores com aproximadamente 5.000 clientes cada**, ou 500 mil cadastros.
Cadastro não equivale a acesso simultâneo. API e frontend desta revisão foram
validados e publicados, com ambos os serviços saudáveis. Na rodada web,
Functions, Rules, proxy e APK não foram alterados em produção. Não há homologação de capacidade
para essa referência.

Na rodada posterior de diagnósticos mobile descrita abaixo, API, builder e
proxy tiveram imagens publicadas, e o APK final foi gerado e disponibilizado.

## Visao geral

```text
Admin React/Vite
  -> API HTTP: dashboards, provedores/configuração, equipe e chamados paginados
  -> shared/contracts + shared/api/functionRequests: comandos legados restantes
     -> Firestore function_requests -> Functions handleFunctionRequest
  -> Firestore/Storage SDK: caminhos ainda não migrados

App Flutter
  -> ProviderConfigNormalizer
  -> api-service para SGP/login/diagnosticos
  -> Firestore para config, tickets e notificacoes permitidas

api-service
  -> rotas Express modulares
  -> Firebase Admin para auth/dados
  -> proxy-sgp para cache/rotas SGP legadas

proxy-sgp
  -> PostgreSQL (cache de clientes SGP)/Redis
  -> SGP externo

jobs-worker
  -> BullMQ/Redis persistente
  -> sincronização e lembretes -> SGP/Firestore/PostgreSQL/FCM
```

## Camadas

- `shared/contracts`: nomes de requests, payloads, resultados e modelos comuns.
- `admin-painel/src/shared`: infraestrutura de API/Firebase.
- `admin-painel/src/features`: services e regras de dominio.
- `functions/src/app`: router, permissao, auditoria, erros e resposta.
- `functions/src/handlers`: dominios de provedores, tickets, usuarios, SGP,
  clientes, backups, dashboards e notificacoes.
- `api-service/src/routes`: fronteira HTTP.
- `api-service/src/services`: Firebase Admin, SGP, proxy e auditoria.
- `admin-painel/src/shared/api/panelHttp.ts`: HTTP autenticado, cache curto de
  leitura por identidade e reunião de solicitações idênticas.
- `services/apk-builder`: unico runtime local de geracao APK/AAB.
- `app-flutter/unified/lib/core/models`: normalizacao de config remota no app
  movel canonico.

## Dados sensiveis

Tokens SGP e credenciais ficam em:

- `provedores/{providerId}/secrets/sgp`
- Firebase secrets/params
- variaveis de ambiente do host

Esses dados nao devem ser escritos em `provedores/{providerId}` nem em logs.

## Decisoes

- O `api-service` é a fachada HTTP. Dashboards e personalização do painel usam
  HTTP; `function_requests` permanece nos comandos ainda não migrados e em
  consumidores legados. Não existe corte geral da fila nesta entrega.
- Personalização usa `GET /admin/providers/:providerId` e
  `PATCH /admin/providers/:providerId/config`, preservando o schema permitido e
  a autoridade atual no Firestore. O provedor não ganha permissão sobre token,
  destino da integração ou geração de aplicativos.
- Equipe e chamados usam `/admin/users/page` e `/admin/tickets/page`, com cursor,
  25 itens por padrão e máximo de 100. O cursor de chamados usa `updatedAt` e ID;
  documentos sem esse campo exigem reconciliação. Filtros visuais dessas listas
  abrangem a página atual. Rotas antigas continuam disponíveis.
- Listas de provedores do painel usam `/admin/providers/summaries`, com projeção
  de metadados. A consulta ainda percorre a lista de tenants; não lê os clientes.
- Autorização HTTP verifica revogação e registro Auth atual em cada requisição.
  Middlewares compartilham a verificação somente no mesmo objeto de requisição
  e token; não há cache de autorização entre requisições. Pontos sensíveis que
  revalidam durante a operação usam `verifyFreshToken`, inclusive anexos.
- O cache do painel reúne leituras, guarda até 64 entradas vinculadas ao objeto
  de sessão por até 15 segundos e é limpo nas trocas de sessão e escritas. O polling de
  provedores pausa com a aba oculta. Comandos HTTP não têm repetição automática:
  timeout pode acontecer depois de uma escrita já concluída.
- Configuração pública sanitizada tem cache por processo de até 500 chaves,
  reunião de leituras e TTL de 30 segundos, mais `Cache-Control: public,
  max-age=30`. Escritas HTTP de configuração invalidam a chave local. Outros
  processos/escritores e caches HTTP dependem da expiração; não há invalidação
  distribuída nem promessa de atualização instantânea.
- Dashboard global mantém agregações globais, projeta nomes de provedores e
  limita as contagens por provedor aos seis gráficos exibidos.
- O `proxy-sgp` nao foi removido; ele permanece dono do cache e das rotas SGP
  ainda especificas.
- O schema `ProviderConfig` segue compativel com campos atuais e legados.

## Autoridade dos dados e migrações pendentes

Firebase Auth continua responsável pela identidade e pelos papéis atuais.
Firestore continua guardando dados próprios de negócio, configuração e estado
de RPC; Storage guarda objetos. PostgreSQL continua principalmente como cache
SGP. Sincronizações ainda escrevem PostgreSQL e Firestore independentemente;
esta entrega não oferece transação entre os bancos.

O [plano de rearquitetura](plano-rearquitetura-2026-10-30.md) descreve o destino
de monólito modular, PostgreSQL transacional, outbox e migração por domínio com
um único escritor. Esse destino ainda não foi entregue. Permanecem pendentes
inventário e compatibilidade das versões web/mobile, retirada dos acessos SDK e
RPC por domínio, modelo transacional, reconciliação, recuperação integral,
PITR e aceite dos gates de segurança/operação. O Flutter ainda mantém acessos
Firestore permitidos; otimizar HTTP compartilhado não os remove.

## Publicação e observação de 12/11

O [recibo sanitizado](operations/web-performance-2026-11-12.json) identifica
imagens da árvore modificada sobre `347f186`, com sufixo
`performance-20261112`. Esse identificador não representa uma árvore limpa
integralmente descrita pelo commit. As imagens de retorno preservadas são
`painel_provedores-api-service:rollback-performance-20261112` e
`painel_provedores-frontend:rollback-performance-20261112`.

No Chromium executado no servidor, após aquecer a API, as primeiras aberturas
de Provedores/Equipe/Suporte/Aparência ficaram entre 0,792 e 0,808 s. Retornos
às três primeiras telas levaram 36/42/37 ms dentro do cache de 15 segundos.
Salvar configuração retornou HTTP 200 em 0,839 s, preservando a cor. Não houve
erros JavaScript; na navegação até Aparência o SDK Firestore não foi baixado,
e o módulo do builder foi carregado ao abrir sua tela. O login levou 3,748 s
na primeira execução e 2,722 s na seguinte: a meta de login não está comprovada.
São amostras do navegador no servidor, sem prova de latência no celular do
usuário, percentis sustentados ou capacidade para 500 mil clientes.

## Rodada posterior: diagnósticos mobile

No código do app, `apiEndpoint` preserva prefixos como `/api`.
`DiagnosticBinding` compartilha o ciclo de vida entre os seis diagnósticos,
Meu WiFi e ping, reagindo à configuração, conta e contrato. O controlador WiFi
reúne leituras simultâneas, protege a saída durante a operação e trata a
exibição da senha. Ping isolado nos três estilos usa o mesmo serviço completo;
`DiagnosticPing` e `DiagnosticRuns` são partes extraídas desse serviço. Scanner
tem prazo de dez segundos e cancelamento; gráficos retêm até 120 amostras.

Os seis seletores de diagnóstico usam uma única página
`shared_diagnostico_page.dart`, com o mesmo estado, ações e renderização de
resultados por `MeasurementCard`/`SpeedMeasurementCard`. Cinco estilos são
wrappers de aparência com cores de `LayoutTokens`; a composição foi
padronizada, sem promessa de preservar o visual anterior pixel a pixel.
Valores simulados de RSSI, gateway, ONU e dispositivos foram removidos;
campos sem medição ficam indisponíveis. O serviço não presume WPA2 quando
a integração não informa a segurança. ONU e traceroute têm rótulos no estado
inicial, sem antecipar um resultado medido.

`TracerouteService` atende diagnóstico completo e tela isolada. Na API, o
runner usa uma sonda por salto (`-q 1`), espera de um segundo (`-w 1`) e prazo
global de 25 segundos; preserva saltos parciais no timeout, distingue falha de
execução e só indica destino alcançado quando o IP correspondente aparece.
O resultado declara `origin=server`: a rota medida começa no servidor, não no
aparelho do assinante.

API 125 testes e Flutter 61 testes aprovados,
com análise de `lib` e `test/core` sem problemas. Regressões cobrem os seis seletores
com os mesmos testes/ações e encerramento de streams na troca de contrato.
Preview adicional em 390 × 844 passou nos temas claro/escuro com fontes reais;
seis testes de seletores e um de formatação passaram novamente. `ThemeData` independente evita
misturar cores entre os temas. Isso verifica renderização de teste, não aparelho.
Traceroute autenticado em produção retornou cinco saltos reais, com
`reached=false` e origem no servidor. API e builder tiveram imagens publicadas
nesta rodada. O [APK final Vibe Telecom](https://appisp.com.br/public_apks/f1/vibe/1794516378/7ab4b099-1b95-4138-9342-6649e5530506/app.apk)
foi gerado e teve download HTTP 200 (aproximadamente 30,8 MiB): pacote
`br.com.provedores.vibe`, versão `1.0.1794516378`/code `1794516378`, Android
mínimo 26, alvo 36 e arquitetura arm64. Verificação `apksigner` aprovada, com
certificado igual ao anterior. Hashes do APK, certificado e fonte congelada
constam do [registro operacional](operations/scaling-single-host.md#apk-final-vibe-telecom).
Não havia aparelho disponível via ADB. Os testes não homologam permissões,
cancelamento, WiFi, ping ou desempenho em dispositivo físico, nem a referência
de 500 mil clientes. As migrações de dados/SDKs descritas acima continuam abertas.

No código do proxy WiFi, a leitura normaliza listas diretas e envelopes
`data`/`wifis`, recusando erros e formatos inesperados. Atualização sem nova
senha consulta a credencial atual da rede exata no SGP; valor ausente ou
mascarado causa 422, sem anunciar sucesso. Falhas explícitas do upstream são
recusadas. Recibo final: 37 testes aprovados com Redis real isolado em loopback,
sem testes pulados, e sintaxe verificada; o container de teste foi removido.
O proxy foi publicado e ficou saudável, assim como API e builder;
tag de retorno: `rollback-wifi-20261112`.

## Rodada de 13/11: execução Android em emulador

O [registro de execução](../test-results/android-runtime-2026-11-13/result.json)
documenta teste parcial no AVD `painel_vibe_test`, Android 11 Google APIs
x86_64 com KVM. O APK release `1.0.1794516378` instalou, mas sua execução foi
inconclusiva por `SIGILL` em `libndk_translation.so` na tradução ARM para x86;
isso não comprova defeito do app. Um build debug x86_64 privado, gerado da mesma
fonte com Flutter 3.44.0 em container, executou onboarding e tela de login,
carregando configuração pública da API de produção.

O teste revelou contraste incorreto no campo de identificação e barra de
status no tema escuro. `UnifiedLoginPage` recebeu ajuste de preenchimento e
cores dos campos, alternância de visibilidade da senha e overlay de sistema;
a [captura corrigida](../test-results/android-runtime-2026-11-13/login-corrected.png)
não contém identificação de cliente. Na UI Android, a ação de mostrar senha
mudou o atributo de ocultação de verdadeiro para falso. Também foi removido o
bootstrap de Auth anônimo anterior a `runApp`, rejeitado com
`admin-restricted-operation`: a configuração pública HTTP dispensa esse login.
O erro não apareceu no log posterior à correção.

Passaram 62 testes Flutter; análise dos arquivos alterados sem problemas.
As correções de 13/11 existem somente na fonte e no build debug privado;
nenhum novo APK release foi publicado. A UI bloqueou entrada sem senha e a
API real `/api/check-cpf` retornou 401 para senha vazia. A autenticação do
servidor não mudou; a jornada de primeiro acesso para contas sem senha aguarda
decisão. Diagnósticos autenticados e rádio WiFi não foram testados. Emulador
não constitui homologação física, nem altera os limites de capacidade e
migração registrados acima.

## Redesenho Flutter em andamento — 2026-11-16

`core/painel_page.dart` concentra o shell de aproximadamente 256 linhas, com
quatro abas: Início, Faturas, Conexão e Suporte; Conta passa a rota secundária.
As páginas ficam em `core/pages/customer/`, e `CustomerRoutes` normaliza aliases
e respeita `enabled`/`features`. `LayoutSelector.dashboard` usa
`CustomerHomePage`; os layouts legados permanecem fora do fluxo principal.
`FinanceiroProvider` reúne consultas simultâneas e protege atualizações após
`dispose`.

Os seis IDs de diagnóstico e o teste de velocidade compartilham
`shared_diagnostico_page.dart`, `DiagnosticView` e o modelo de apresentação;
velocidade usa `speedOnly`. Os testes são apresentados em quatro grupos,
traceroute identifica origem no servidor e resultados distinguem inconclusivo,
indisponível e falta de permissão. Cancelar preserva resultados já obtidos.
Compartilhamento usa resumo com campos permitidos, sem CPF, SSID, IP, MAC ou
senhas e sem upload automático. `DiagnosticHistoryStore` mantém até 20 registros
locais por provedor e conta, sem scores fictícios.

A suíte completa passou com 103 testes e `flutter analyze` sem problemas.
A compilação nativa do preview x86_64 passou; o
[teste Android nativo](../test-results/redesign-2026-11-16/runtime.json)
executou a verificação rápida com medições reais do emulador e backend
demonstrativo indisponível. A prévia de compartilhamento abriu sem envio
externo; histórico foi salvo, lido e limpo. O diagnóstico completo foi
interrompido pela UI, preservando resultado parcial salvo e relido, sem
exceções não tratadas no log. Um retorno de `Future` no `setState` do histórico,
encontrado nessa execução, foi corrigido e coberto por
`diagnostic_history_page_test`. A navegação Android Início → Conexão → Suporte
→ Conta → voltar também passou sem exceções não tratadas.

A [galeria publicada](https://appisp.com.br/public_apks/f1/prints/redesenho-app-2026-11-16/index.html)
contém 80 capturas novas, com 60 estados/telas em cinco temas, também em
`artifacts/redesenho-app-2026-11-16`. Capturas de andamento e resultados usam
cenários explicitamente simulados; são evidência visual separada do runtime
funcional descrito acima.

O fluxo de gerente concluiu o job `b500dcc3-2901-48af-8611-9ba277abebfd` com
`SUCCEEDED`. O [APK disponibilizado](https://appisp.com.br/public_apks/f1/vibe/1794840955/b500dcc3-2901-48af-8611-9ba277abebfd/app.apk)
foi baixado com HTTP 200: versão `1.0.1794840955`, pacote
`br.com.provedores.vibe`. `apksigner verify` passou e o certificado corresponde
ao anterior. Identificadores SHA-256:

- APK: `5772411280c00af13575f45063de7bc8a6b2c93275091bee86384388aa41b600`.
- Certificado: `3f0b63d7a55a7303b877ed7a3fbbcecde241d65342f8feea5fb3df0bacedde45`.
- Fonte Flutter host/imagem, coincidentes com digest LF:
  `d96b9dd95c4a65d17a7ed7914394159522b627b2847e957a9024bbbd1326b425`.

O teste usou conta demonstrativa isolada: autenticação de cliente real, SGP e
ONU física não foram homologados, nem a capacidade para 500 mil cadastros.
As evidências Android de 13/11 pertencem à fonte daquela rodada.

## Operação para múltiplos provedores

`jobs-worker` executa sincronizações e lembretes em BullMQ, com Redis persistente separado do cache. API e proxy compartilham o coordenador SGP de `shared/runtime/upstream.js`. Administradores exigem papel explícito; assinantes usam identidade composta por provedor e CPF e senha no login.

Listagens de clientes são paginadas por cursor e dashboards usam agregações. Detalhes, limites de recursos, implantação e restrições do servidor único: [scaling-single-host.md](operations/scaling-single-host.md).

O [ensaio HTTP controlado de 12/11](operations/capacity-100-providers-2026-11-12.json)
usou 100 provedores e espaço sintético de 500 mil identidades, sem banco povoado
com esse volume. Com 100 requisições simultâneas e duas verificações Auth
simuladas de 275 ms cada, os p95 foram 633,67 ms com cache, 867,54 ms sem cache
e 1.683,53 ms com SGP de 500 ms; esses cenários retornaram integralmente HTTP
200. Sobrecarga concentrada em dez tenants, com concorrência 200, retornou 120
HTTP 200 e 880 HTTP 503 em mil pedidos. Houve pico de quatro chamadas SGP por
tenant e zero divergência de isolamento nas fixtures. O ensaio identifica
limites de proteção; não homologa Firestore/Auth/SGP reais, dispositivos, banco
de 500 mil clientes ou o host com outros serviços concorrentes.
