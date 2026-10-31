# Plano de rearquitetura do painel_provedores

Data: 30/10/2026 — America/Fortaleza.  
Revisão: 3 — documento único com arquitetura, execução, permissões e matriz de achados/evidências.  
Status: direção aprovada; implementação e critérios de aceite ainda pendentes. Esta revisão altera documentação, não a produção.  
Escopo: plataforma SaaS Unify, painel web, aplicativo Flutter, integrações SGP, dados, filas, builds Android e operação.

Leitura rápida: [achados e evidências](#15-matriz-de-achados-e-evidências), [permissões dos painéis](#5-identidade-segurança-e-segredos), [compatibilidade e autorização](#6-contrato-http-e-experiência-dos-clientes), [recuperação](#7-operação-no-servidor-único) e [fases e primeira entrega](#9-fases-de-execução).

## 1. Objetivo e compromisso de engenharia

Reconstruir a arquitetura para operar com isolamento entre provedores, dados consistentes, experiência rápida e recuperação verificável. A referência de produto é **20 provedores com aproximadamente 5.000 assinantes cada**, totalizando 100 mil cadastros. Isso não equivale a 100 mil acessos simultâneos.

A direção é um **monólito modular em TypeScript, exposto por uma API HTTP, com PostgreSQL como banco transacional dos dados próprios, workers e integração SGP única**. React e Flutter continuam como clientes. Firebase Auth continua como serviço de identidade; FCM continua para push. Firestore sai gradualmente do caminho principal dos dados de negócio e da comunicação de comandos administrativos.

Esta mudança inclui arquitetura, modelo de dados, autorização, operação e experiência de falha. Não se limita a trocar Express por Fastify ou organizar pastas. Não é necessário redesenhar visualmente todas as telas para realizar a migração.

O plano descreve trabalho futuro. As correções anteriores de segurança, limites, backup e desempenho só serão consideradas encerradas mediante evidências específicas. A [matriz de achados e evidências](#15-matriz-de-achados-e-evidências) é parte obrigatória deste plano e distingue código, teste, implantação e distribuição mobile.

**Divisão de produto definida pelo usuário:** o administrativo SaaS, operado pela nossa equipe, recebe e cadastra o token fornecido pelo provedor e controla a geração dos aplicativos. O painel do provedor se concentra nas informações, personalização e operação do seu app. O provedor não pode cadastrar, visualizar o valor armazenado, substituir ou remover token, alterar o destino da integração, nem gerar, assinar ou publicar aplicativos. Essa divisão deve valer no backend e nos acessos diretos, além da interface.

### Regras para executar

1. Migrar por domínio, com contratos compatíveis e um provedor piloto antes de ampliar.
2. Ter **um único escritor e uma única fonte de verdade por domínio e provedor em cada etapa**.
3. Fazer migrações reproduzíveis, retomáveis e auditáveis; contagem de documentos sozinha não comprova integridade.
4. Não remover rotas, coleções, identidades, assinaturas Android ou versões antigas sem mapear seus consumidores.
5. Não reduzir autorização para melhorar tempo de resposta.
6. Não substituir nem revogar a credencial SGP em uso sem acesso e validação no sistema de origem. Sua cópia pública deve continuar removida.
7. Não alterar recursos ou serviços dos outros projetos do servidor para acomodar esta mudança.
8. Não declarar capacidade, disponibilidade ou recuperação sem ensaio e evidências.
9. Nenhum achado crítico/alto ou P0 será considerado resolvido sem commit, teste correspondente, resultado e situação da implantação. Justificar achados refutados com evidência verificável.
10. Corrigir autorização, validação e integridade independentemente da troca do framework HTTP. Express não foi demonstrado como gargalo.
11. Validar uma entrega completa de configuração antes de ampliar a fundação para todos os módulos. Piloto por domínio e piloto integrado são etapas distintas.

## 2. Ponto de partida e problemas a eliminar

| Situação atual | Consequência | Tratamento no plano |
| --- | --- | --- |
| Painel combina API HTTP, acesso direto ao Firestore e `function_requests`/`function_responses` | Contratos e autorização distribuídos; várias etapas para uma ação | API única e adaptadores temporários; retirar RPC por documentos |
| Dashboard já usa HTTP, mas outras operações continuam na fila antiga | Melhorias de uma tela não resolvem a arquitetura inteira | Migrar domínio por domínio, incluindo mutações |
| `functions/src/app/requestRouter.ts` trata qualquer erro de aquisição do lock como duplicidade e não possui recuperação por lease | Falha de infraestrutura pode aparentar sucesso e deixar requisição sem resposta | Corrigir o legado enquanto existir; depois substituí-lo |
| Sincronização grava PostgreSQL e Firestore em operações independentes | Falhas intermediárias podem produzir visões divergentes | Transação local, outbox e projeções reconciliáveis |
| POST em `api-service/src/routes/providers.routes.ts` filtra credenciais na raiz, mas aceita estruturas aninhadas genéricas | Administrador autorizado pode reintroduzir segredo em documento público; Admin SDK não é limitado pelas regras do cliente | Schemas explícitos de entrada/saída e separação física do modelo público/privado |
| Dashboard do provedor calcula instalações como 68% dos clientes e usa séries/tendências fixas; há badge fixo | Informações apresentadas sem medição correspondente | Mostrar N/D ou dados reais com definição e origem |
| Builder possui acesso à credencial administrativa compartilhada com serviços de produção | Execução de build pode alcançar permissões além da geração do APK | Credenciais distintas e build separado da assinatura/publicação |
| PostgreSQL é principalmente cache SGP; Firestore guarda boa parte do domínio | Migrar banco exige decidir quem é dono de cada dado | Matriz de autoridade, schema e migração por domínio |
| Servidor único divide memória, CPU, disco e rede com outras aplicações | Contenção e falha física compartilhada | Orçamentos medidos, serviços auxiliares limitados e plano de recuperação |

A possibilidade de nova gravação indevida de segredo é uma falha do caminho de escrita identificado no código. **Não é uma afirmação de que o token privado esteja novamente publicado.** A correção deve abranger também respostas, auditoria, backups de configuração e outras rotas privilegiadas.

### Evidências existentes e seus limites

- Medição recente de restauração da sessão do provedor: aproximadamente 2,79 s até os dados, sendo 1,54 s de autenticação e 1,25 s de API. É uma amostra, não um percentil representativo.
- Testes anteriores de login real chegaram a aproximadamente 2,30 s no SaaS e 1,62 s no provedor, em condições distintas. Não comparar amostras diferentes como se fossem um experimento controlado.
- O teste sintético de sobrecarga teve 435 respostas 200 e 565 respostas 503 em 1.000 requisições com concorrência 200 e SGP simulado de 500 ms. A proteção funcionou; isso não homologa o produto nessa carga.
- Os backups atuais incluem cópia externa e validação de PostgreSQL/Redis. Ainda falta ensaio completo de recuperação Firestore/Auth em ambiente isolado.
- A telemetria atual de experiência é limitada e volátil. Deve ganhar persistência, segmentação e contagem explícita de falhas.

Referências locais: [arquitetura atual](architecture.md), [operação no servidor único](operations/scaling-single-host.md), [desempenho do dashboard](operations/dashboard-performance.md), [medição de login](operations/login-followup-2026-10-30.json) e [carga sintética](operations/capacity-report.json).

### Registro de auditoria e rastreabilidade

A auditoria externa examinou `69bc581`. Na revisão local de 30/10/2026, HEAD e `main` remoto ainda eram `69bc5818e4149ae91b1d028d5634f2af84785972`, com correções posteriores não commitadas. Alguns arquivos de containers, o pacote da Function e as regras publicadas foram comparados com os locais. Isso comprova somente o escopo comparado; as imagens não tinham identificação de revisão Git.

Foram aprovados 37 testes da API, 67 das Functions e 8 testes selecionados de helpers/speed test naquela revisão. A repetição das regras ficou bloqueada pela incompatibilidade Java 17/CLI exigindo Java 21. Esses resultados não encerram automaticamente achados nem substituem testes de aceitação específicos.

| Grupo de achados | Situação inicial | Destino obrigatório |
| --- | --- | --- |
| C1, C2, C3, C6 | Correções específicas presentes; fechamento integral e clientes legados ainda exigem evidências | F0/F1 e reconciliação de dados/acesso nas fases aplicáveis |
| C4, C5 | Escrita aninhada de segredo e validação de destinos SGP abertas | F1, prioridade P0 |
| C7, C8, C9 | Sync parcialmente corrigido; lock aberto; falhas de faturas precisam de cobertura específica | F1 e consistência completa em F5 |
| C10, C15 | Mudanças no código; validação específica de notificações/contagem e versões ainda pendente | F1/F6 |
| C11 | Restauração por mesclagem ainda aberta | F1/F4; separar personalização de credenciais |
| C12, C13 | Colisões Android/artefatos e perda de símbolos ainda abertas | Contenção em F1; ciclo completo em F7 |
| C14 | Formulário comercial simula sucesso | F1, com destino real ou ação explícita de contato |
| C16 | Limites implementados; autorização individual e homologação conjunta pendentes | F1/F7 |
| E1–E9 | Indicadores/diagnóstico, privilégios do builder, nova política SaaS, revogação, rastreabilidade, recuperação, rotação SGP e caminhos alternativos | Matriz vinculada com prioridade, fase e aceite |

A matriz da seção 15 contém cada C1–C16, arquivos/artefatos examinados, limites dos testes e critérios de encerramento. Não usar a auditoria antiga como descrição automática da produção atual, nem usar as alterações locais como prova automática de correção.

## 3. Arquitetura de destino

```text
Painel React                         Aplicativo Flutter
  sessão web em cookie                 token de identidade
              \                         /
                 Caddy / HTTPS
                       |
           API TypeScript / HTTP modular
                       |
     identidade e autorização + módulos de domínio
                       |
       +---------------+----------------+
       |               |                |
   PostgreSQL       Redis cache     Adapter SGP
   domínio próprio  descartável     HTTP limitado
   projeções SGP                         |
   operações/outbox                  SGP externo
       |
   Dispatcher outbox -> BullMQ / Redis persistente -> Workers
                                                  | SGP / FCM
                                                  | projeções legadas
                                                  | tarefas de build

Build Android restrito -> assinatura restrita -> publicação em Storage
API/Workers -> logs, métricas e traces com dados sensíveis removidos
PostgreSQL/objetos/configuração -> backup externo + ensaio de restauração
```

A API e os workers compartilham módulos e contratos, mas executam como processos separados. O adapter SGP é um componente interno compartilhado, não exige um novo microserviço.

### Decisões técnicas

| Área | Decisão de destino | Justificativa / limite |
| --- | --- | --- |
| Painel | React, TypeScript, Vite; Tailwind/Radix existentes | Preservar investimento e migrar acesso a dados sem reescrever interface inteira |
| Mobile | Flutter/Riverpod, aplicação canônica `app-flutter/unified` | Compatibilidade white-label e implantação gradual por versão |
| Backend | Node.js LTS suportado, TypeScript estrito; Fastify como destino condicionado a ADR | Schemas/contratos independem do framework; Express pode atender a primeira entrega sem bloquear correções |
| Banco próprio | PostgreSQL, SQL parametrizado com `pg`, migrations versionadas | Transações, constraints e consultas previsíveis; administração passa a ser responsabilidade operacional nossa |
| Identidade | Firebase Auth inicialmente | Evitar reconstruir autenticação, recuperação de senha e validação de identidade |
| Sessão web | Firebase durante a transição; cookie opaco HttpOnly/Secure após controlar os acessos administrativos legados | Mudança de sessão e de autoridade de permissões tem gate próprio; não substitui autenticação dos SDKs Firebase |
| Mobile | Token Firebase verificado na API, com autorização de domínio | Cookie web não é imposto ao aplicativo |
| Cache | Redis volátil separado | Cache nunca será a única cópia de um dado de negócio |
| Fila | BullMQ em Redis persistente `noeviction` + operações e agendas no PostgreSQL | Reconstrução inclui trabalhos pendentes, futuros, recorrências e cancelamentos; cache permanece separado |
| Segredos | Google Secret Manager, versões explícitas por integração; acesso por serviços restritos | Referência ativa no banco; valor nunca retorna ao painel do provedor, configuração pública ou builder |
| Eventos internos | Outbox transacional + consumidores idempotentes | Evitar perda entre commit de negócio e publicação; sem promessa de entrega exatamente uma vez |
| Arquivos | Storage privado para dados restritos; URLs públicas somente para assets/APKs explicitamente públicos | Separar metadados de negócio de objetos e de segredos |
| Push | FCM | Resultado aceito pelo FCM não comprova leitura ou instalação |
| Operação | Docker Compose no servidor atual | Simplicidade; sem alta disponibilidade física |
| Observabilidade | Logs estruturados, métricas persistidas e OpenTelemetry; armazenamento com retenção e orçamento | Escolher backend operacional na fase 0; não instalar uma suíte pesada sem medir recursos |

Versões, imagens e bibliotecas serão fixadas em lockfiles e digests na implementação, após checar suporte e compatibilidade. Upgrade de versão principal do PostgreSQL não será combinado com a primeira troca de autoridade dos dados.

**Decisão sobre Fastify:** o benefício esperado é padronizar validação/serialização e contratos, não uma promessa de resolver latência. O custo inclui plugins/middlewares, erros, autenticação, rate limits, testes e compatibilidade. Antes da troca, comparar uma rota representativa e registrar custo/benefício no ADR. Se atrasar a primeira entrega, manter Express nela e agendar a troca separadamente. PostgreSQL é escolhido por autoridade, transações e integridade dos dados próprios, não pelo número de 100 mil cadastros isoladamente.

Não fazem parte da arquitetura inicial Kubernetes, Kafka, service mesh, microserviços por tela nem event sourcing completo. A outbox é mecanismo de entrega confiável, não obrigação de reconstruir todo o sistema por eventos.

### Limites entre módulos

| Módulo | Responsabilidade |
| --- | --- |
| `identity-access` | Identidade externa, sessões, memberships, papéis, revogação e MFA administrativo |
| `tenants` | Provedores, ciclo de vida, limites, suspensão e cadastro administrativo |
| `provider-config` | Configuração white-label versionada, publicação e projeção pública |
| `subscribers` | Identidade local, vínculo com provedor, dispositivos e referências SGP |
| `tickets` | Tickets, mensagens, anexos e transições de estado |
| `notifications` | Campanhas, destinatários, tentativas e eventos de entrega disponíveis |
| `sgp` | Adapter, normalização, limites, sincronização, comandos e reconciliação |
| `dashboard` | Modelos de leitura, agregações, definição e atualização das métricas |
| `builds` | Pedido de build, execução, assinatura, publicação e rastreabilidade |
| `operations` | Operações assíncronas, outbox, auditoria e idempotência |

Rotas chamam casos de uso; casos de uso usam repositórios e adapters. Um módulo não acessa tabelas internas de outro de forma improvisada. Consultas agregadas usam interfaces/projeções documentadas. Evitar interfaces e abstrações sem uma necessidade concreta.

## 4. Dados, autoridade e consistência

### Matriz de autoridade no estado final

| Dado | Fonte de verdade | Outras representações |
| --- | --- | --- |
| Credenciais de login e identidade externa | Firebase Auth | Referência de UID no PostgreSQL; sem copiar senhas |
| Vínculos, papéis, sessões e suspensão na plataforma | PostgreSQL | Cache com invalidação e prazo de validade definidos |
| Provedor, configuração, tickets, campanhas e histórico de builds | PostgreSQL | Projeções de leitura e compatibilidade temporária |
| Cadastro comercial, contratos, faturas e situação financeira | SGP | Projeção local com origem, versão quando disponível e horário da última sincronização |
| Dispositivos, preferências e atividade no aplicativo | PostgreSQL | Eventos/contadores agregados e FCM como canal |
| APKs, anexos e assets | Storage | Metadados, permissões, checksum e versão no PostgreSQL |
| Segredos SGP | Secret Manager, gerido pela equipe SaaS através da API | Referência e versão ativa em área privada; provedor vê somente estado da integração |
| Credenciais de serviço e assinatura | IAM/armazenamento privado restrito por serviço | Sem compartilhamento da conta administrativa com builder; chaves de assinatura fora do executor |
| Fila operacional e agendas | PostgreSQL para intenção, recorrência, próxima execução e cancelamento | BullMQ para agendamento e execução |

Alterar uma projeção local não altera um contrato ou uma fatura no SGP. Comandos financeiros e de rede vão ao SGP com autorização e reconciliação; nunca são simulados como sucesso no cache.

### Modelo mínimo a desenhar antes de migrar

- `tenants`, `identities`, `memberships`, `sessions` e histórico de mudança de acesso.
- `subscribers`, `subscriber_external_refs`, `devices`, `notification_preferences` e projeções de contratos SGP.
- `provider_configs` versionadas, assets e referências privadas de integração.
- `tickets`, `ticket_messages`, anexos e histórico de transições.
- `notification_campaigns`, `notification_recipients`, tentativas e resultados disponíveis.
- `build_jobs`, `build_artifacts` e referências de assinatura.
- `operations`, `schedules`, `outbox_events`, `consumer_receipts`, `idempotency_keys`, `audit_events` e checkpoints de migração/sincronização.
- Mapa explícito `legacy_id -> UUID`, incluindo tenant, origem e regras de colisão.

Usar UUID opaco como identificador próprio. CPF, email e nome do provedor não são chaves de autorização nem IDs públicos. Preservar os UIDs atuais do Firebase através do mapeamento; não recriar contas só para trocar sua aparência.

Toda tabela pertencente a um provedor tem `tenant_id NOT NULL`, índices apropriados e constraints compostas que impeçam referências cruzadas. A unicidade do cliente externo é por tenant e origem, não global por CPF. Um assinante pode ter vários contratos.

Datas persistidas em UTC; agenda e apresentação respeitam America/Fortaleza quando aplicável. Valores monetários usam decimal ou centavos, com moeda e precisão definidas. Paginação por cursor é estável mesmo com inserções concorrentes. Alterações concorrentes de configuração usam versão/ETag para impedir sobrescrita silenciosa.

### RLS e isolamento

Aplicar Row-Level Security nas tabelas de tenant como defesa adicional. A conexão da aplicação não será superuser, não terá `BYPASSRLS` e não será dona das tabelas. Migrações usam credencial separada.

O contexto de tenant será definido dentro da transação, com escopo local, e nunca deixado persistente em conexão devolvida ao pool. Ausência de contexto deve negar acesso. Testar reutilização de conexão, caminhos de erro, jobs e tentativas com IDs de outro provedor.

Operações globais do SaaS terão políticas/privilégios explícitos e trilha de auditoria. Não resolver acesso global concedendo bypass irrestrito ao processo inteiro. O tenant solicitado na URL/body só é usado depois da validação do vínculo do usuário.

### Outbox, jobs e efeitos externos

Uma transação grava a mudança própria, a intenção da operação e seu evento na outbox. O dispatcher publica depois do commit; marcar publicação não significa conclusão do trabalho. Um reconciliador reenfileira operações pendentes/interrompidas mesmo se o Redis for perdido. Retenção da outbox não remove a única informação necessária para essa reconstrução.

Agendas persistem regra, timezone, próxima ocorrência, versão, estado de cancelamento, política para execução atrasada e chave de deduplicação por ocorrência. O reconciliador deve reconstruir também jobs futuros/recorrentes sem ressuscitar cancelamentos. Reconexão ao mesmo Redis não comprova recuperação após perda total; isso exige ensaio próprio.

Consumidores usam identificação de evento, chave de idempotência com escopo tenant/operação, lease e controle de versão. Tratar duplicação, expiração de worker e eventos fora de ordem. Uma geração antiga de sincronização não pode sobrescrever uma nova.

Para efeitos externos sem idempotência no SGP, um timeout após envio gera estado **resultado desconhecido**, seguido de consulta/reconciliação. Não repetir desbloqueio, alteração de rede ou outra mutação cegamente. Push pode duplicar após uma falha no instante entre envio e persistência; documentar e reduzir esse risco sem prometer exatamente uma vez.

## 5. Identidade, segurança e segredos

### Matriz de produto: administrativo SaaS, provedor e assinante

`superAdmin` representa a equipe da plataforma; `providerAdmin` representa o administrador de um tenant; `subscriber` representa o assinante. A presença de `providerId` não concede capacidade administrativa. Toda permissão nova é negada até ser explicitamente atribuída.

| Capacidade | Administrativo SaaS | Painel do provedor | App do assinante |
| --- | --- | --- | --- |
| Cadastrar, suspender e administrar provedores | Sim, com auditoria | Não | Não |
| Cadastrar/substituir/remover token SGP recebido do provedor | Sim, por endpoint exclusivo e reautenticação | **Não** | **Não** |
| Recuperar valor do token armazenado pela interface | Sem exibição de rotina; formulário de substituição não devolve o valor | **Não** | **Não** |
| Alterar URL SGP, app de integração, referência do segredo ou URL interna da API | Sim, após validação de destino e tenant | **Não** | **Não** |
| Consultar estado da integração e última atualização | Sim | Sim, somente seu tenant e sem dados sensíveis | Apenas disponibilidade necessária à jornada |
| Iniciar, repetir, cancelar, assinar ou publicar build APK/AAB | **Somente SaaS** | **Não** | **Não** |
| Alterar applicationId, versão nativa, keystore e canais de distribuição | **Somente SaaS** | **Não** | **Não** |
| Ver versão pública e link do aplicativo já publicado | Sim | Sim, do próprio app | Download dos artefatos explicitamente públicos |
| Personalizar logo, cores, layout, banners, textos, FAQ, menus e contatos permitidos | Sim | Sim, do próprio app, dentro do schema permitido | Leitura da configuração pública |
| Salvar/publicar configuração dinâmica permitida, sem novo binário | Sim | Sim, do próprio app, com versionamento e validação | Leitura da configuração publicada |
| Consultar indicadores, atividade do app e informações de usuários autorizadas | Visão global e por tenant | Somente seu tenant e campos necessários | Somente seus dados |
| Operar tickets, avisos e campanhas do app | Sim | Somente seu tenant, com limites e permissões específicas | Abrir/acompanhar próprios tickets e notificações permitidas |
| Restaurar personalização | Sim | Somente versão sanitizada do próprio app | Não |
| Administrar usuários internos SaaS e conceder privilégios | Somente SaaS | Não; eventual equipe do tenant tem papéis limitados, sem autopromoção | Não |

As capacidades de personalização/operação são o escopo inicial proposto para o provedor; novas funções passam pela matriz, sem ampliar implicitamente acesso a integração, builds ou administração global. Comandos comerciais/financeiros/de rede do SGP continuam em casos de uso separados com autorização específica; editar o app não concede acesso irrestrito ao ERP.

Esconder botões não atende ao requisito. Negar requisições forjadas em HTTP, `/sgp`, callables, `function_requests`, Firestore, Storage e serviços internos. A identidade dos jobs deriva do solicitante validado, nunca de papel/tenant informado apenas no payload. O worker revalida a autorização antes do efeito privilegiado; cancelar autorização deve impedir job ainda não executado.

No legado, corrigir também permissões sobre `provedores/{id}/secrets`, backups que contenham credenciais e wildcards de subcoleções. Uma regra específica restritiva não anula outra regra coincidente que permita acesso; revisar todas as permissões sobrepostas. [Referência Firebase](https://firebase.google.com/docs/rules/rules-behavior). Antes de bloquear acesso direto do provedor, separar seu formulário de personalização da edição de integração. A leitura de secrets não pode continuar sendo requisito para editar uma cor.

Publicar uma configuração dinâmica permitida é diferente de publicar um APK/AAB: o provedor pode fazer a primeira operação no próprio app. Alterar personalização dinâmica não dispara build automaticamente. Campos que exigem novo binário são geridos pelo SaaS; um eventual pedido de alteração do provedor não enfileira nem autoriza build por si só. O provedor pode consultar a versão pública, mas não recebe logs de build, símbolos ou chaves.

### Sessão e autorização

- Manter login gerenciado. Durante a migração, preservar Firebase Auth onde os SDKs ainda dependem dele. Implantar cookie opaco somente após o gate de transição da seção 6; a fase 3 prepara esse mecanismo, não impõe corte prematuro.
- No estado final, a API troca uma comprovação recente de identidade por sessão web, validando revogação e conta desativada na emissão/renovação.
- Cookie de sessão com entropia criptográfica, apenas seu hash no armazenamento, `HttpOnly`, `Secure`, escopo restrito, `SameSite` definido e proteção CSRF nas mutações. Validar Origin e política de CORS. Não aceitar o token de identidade enviado em URL.
- No estado final, PostgreSQL mantém os vínculos e permissões. Desativar acesso pela plataforma revoga sessões e permissões de forma transacional, com invalidação do cache. Durante coexistência, a suspensão só é concluída depois de bloquear também todos os acessos legados aplicáveis.
- Definir e testar limite máximo de 60 s para propagação de revogação nos caches internos. Ações administrativas sensíveis consultam estado atualizado e exigem reautenticação quando apropriado.
- Desativação feita diretamente no Firebase também precisa ser detectada. Projetar verificação periódica/renovação com prazo máximo explícito; para sessão administrativa, não permitir estado externo de autorização vencido além de 60 s sem nova verificação bem-sucedida. Falha desse controle deve negar a ação protegida.
- Esses 60 s são requisito de projeto, ainda não implementado. Medir custo e disponibilidade antes de ativar a política. Não retirar a checagem atual de conta ativa sem substituição equivalente.
- MFA para administradores SaaS e contas privilegiadas de provedor, com recuperação segura. Confirmar suporte e eventual custo do plano de identidade antes da implantação.
- Mobile continua usando token de identidade, associado ao tenant/assinante local. Renovação, perda de acesso, troca de provedor e conta suspensa precisam de testes próprios.
- Senha central do assinante é validada pelo SGP e nunca persistida em log, evento, fila ou banco próprio.

### Indisponibilidade da verificação de acesso

| Situação | Comportamento requerido |
| --- | --- |
| Conta desativada, sessão revogada ou papel comprovadamente insuficiente | Negar com código de autenticação/permissão apropriado; encerrar sessão quando aplicável |
| Serviço de identidade indisponível e última verificação externa ainda dentro de 60 s | Somente leituras administrativas ordinárias podem usar o estado válido em cache, após checar permissões locais |
| Verificação externa indisponível e estado mais antigo que 60 s | Negar novas requisições administrativas protegidas com `503 authorization-unavailable`; não devolver dados novos nem fingir sessão revogada |
| Troca de token/destino SGP, alteração de acesso, build/assinatura/publicação ou restauração sensível | Exigir verificação externa atualizada na ação e reautenticação recente conforme ADR; indisponibilidade bloqueia a operação |
| Configuração pública, página pública e download explicitamente público | Permanecem independentes da sessão administrativa |

Mensagem ao usuário: “Não foi possível verificar seu acesso agora. Tente novamente.” Manter formulário e navegação, sem repetir mutação automaticamente nem mostrar dados antigos como atualização bem-sucedida. Registrar falha na disponibilidade da jornada e separar causa externa/interna; não excluí-la silenciosamente do indicador. Essa política só pode ser anunciada como efetiva quando HTTP e caminhos legados cumprirem o mesmo limite.

### Segredos e superfície pública

Schemas de entrada e saída usam lista de campos permitidos, inclusive em objetos aninhados. Segredo não deve apenas ser removido na serialização depois de salvo: o endpoint público de configuração não pode aceitá-lo como dado de configuração.

Separar atualização pública de configuração e atualização privada de integração. A segunda é exclusiva do administrativo SaaS, inclusive teste de credencial candidata e alteração de URL. Registrar auditoria sem valor de token, senha, cookie, chave de assinatura, CPF completo ou payload bruto de SGP. Aplicar a mesma regra a erros e traces.

### Cadastro e ciclo de vida do token fornecido pelo provedor

1. O provedor entrega a credencial à equipe SaaS por canal restrito. Não usar ticket comum do app, campo de personalização ou documento público como transporte/armazenamento de segredo.
2. No administrativo SaaS, selecionar o tenant e inserir token/URL/app em formulário exclusivo. Validar papel no servidor; não persistir o valor em localStorage, analytics, log de requisição ou histórico do formulário.
3. Criar uma versão candidata no Secret Manager vinculada ao tenant. Só serviço de cadastro pode criar versões; somente API/worker SGP autorizados leem as versões necessárias. Usuários finais e builder não possuem IAM de acesso.
4. Validar destino antes de transmitir credencial e testar integração por operação sem efeito comercial. URL e token formam uma configuração versionada; não combinar token de um tenant com destino de outro.
5. Ativar a referência da versão validada em transação no banco com auditoria/outbox. O banco armazena referência/versão e estado, nunca o token. Falha anterior à ativação mantém a integração existente; versões candidatas órfãs são reconciliadas.
6. Invalidar o cache por versão e comunicar apenas sucesso/erro seguro. O painel do provedor recebe `configurada`, `pendente`, `indisponível` e última verificação, nunca o valor ou resposta bruta do SGP.
7. Após validar o funcionamento, tratar revogação da versão antiga no SGP com seu administrador. Desabilitar versão no Secret Manager não revoga o token no upstream. Não reativar automaticamente uma credencial sabidamente comprometida.

A adoção do Secret Manager depende da configuração de IAM, acesso, custo e recuperação confirmados na fase 0. Até sua migração, o segredo privado existente pode continuar em Firestore **somente acessível por backend autorizado**, com administração pelo endpoint SaaS. Essa ponte não permite leitura/escrita direta pelo painel do provedor. Identidades de bootstrap do host terão acesso mínimo e procedimento de rotação; não transferir a conta administrativa ampla para outro arquivo e considerar resolvido.

IAM por segredo e referência de versão explícita seguem as [práticas do Secret Manager](https://docs.cloud.google.com/secret-manager/docs/best-practices). O fluxo candidato → teste → ativação descrito acima é uma decisão deste projeto e precisa ser implementado/testado; não é uma transação automática entre Secret Manager e PostgreSQL.

Restauração de personalização substitui exatamente os campos personalizáveis versionados e preserva explicitamente metadados definidos; não inclui token, destino SGP, permissões, applicationId ou assinatura. Backups antigos misturados exigem classificação e acesso SaaS/backend; fornecer ao provedor somente cópias sanitizadas. Recuperação de segredo tem procedimento separado, exclusivo do SaaS, com validação da versão no upstream.

Usar identidades distintas para API, workers, backup, builder, assinatura e publicação, com permissões mínimas. O builder não recebe service account administrativa, credencial SGP ou acesso ao banco de produção.

Ao permitir configuração de URL SGP, validar destino, protocolo, redirects e resolução de rede. Bloquear destinos internos/metadados não autorizados e mudanças de destino durante redirects/resolução. Endereços privados só entram por configuração operacional explícita quando uma integração realmente exigir.

Backups com segredos permanecem privados e devem ter criptografia e recuperação de chaves documentadas fora do host. Definir retenção e minimização de dados pessoais por categoria. Política jurídica de retenção exige validação própria; este plano não inventa um prazo universal.

**Pendência externa E8:** rotação do token SGP que já esteve exposto. Responsável pela emissão/revogação no upstream: administrador do SGP do provedor. Responsável pelo cadastro, validação e acompanhamento: equipe SaaS. Dependência atual: acesso administrativo ao SGP ou fornecimento de nova credencial por quem o possui. Mitigação: retirar cópias públicas, fechar caminhos de reexposição e restringir acesso backend. Encerramento: nova versão validada, antiga revogada no SGP, caches invalidados e evidência sem valores sensíveis. A pendência permanece aberta até isso acontecer; não interromper a integração apagando o valor privado em uso.

## 6. Contrato HTTP e experiência dos clientes

- Publicar API versionada, por exemplo `/api/v1`, com schemas/OpenAPI e clientes tipados para o painel, independente da adoção imediata de Fastify. Para Flutter, gerar ou manter modelos verificados contra o mesmo contrato.
- Respostas têm IDs opacos, datas normalizadas, limites de tamanho, campos permitidos e erro estável com `code`, mensagem segura e identificador de correlação.
- Leituras normais respondem por HTTP. Tarefas longas retornam `202` e `operationId`; consultar status por polling com backoff. Usar SSE somente se houver benefício medido.
- Mutações críticas aceitam chave de idempotência associada também ao hash do comando; reutilização com comando diferente é rejeitada.
- Manter temporariamente `/api` legado, `/sgp` e contratos do app antigo por adapters. Compatibilidade tem inventário, telemetria e data de revisão, não duração indefinida.
- Eliminar acesso direto do painel às coleções de negócio conforme cada domínio for migrado. Assets públicos podem continuar em CDN/Storage.
- Dashboard lê agregações locais. Exibir `updatedAt`, estado de sincronização e dados desatualizados quando relevante; login não espera sincronizar milhares de clientes.
- Falha não vira zero. Separar carregando, vazio, indisponível e dados antigos. Falha de gráfico secundário não apaga a navegação ou os indicadores já disponíveis.
- Manter divisão de bundles, preload de código, reunião de chamadas e navegação já corrigidos. Cache de dados não pode cruzar usuário/tenant.
- Definir o significado de cada indicador. Base SGP, contas que usaram o app, dispositivos registrados, instalações observadas e usuários ativos são medidas diferentes. FCM token não prova instalação única nem uso ativo.
- Cores, layouts, menus, assets e publicação white-label precisam preservar a normalização dos aplicativos antigos até sua retirada efetiva.

### Matriz inicial de compatibilidade por domínio e cliente

O inventário abaixo parte do código examinado, não de uma contagem de dispositivos em produção. A fase 0 preencherá versão web/commit, `versionCode`/applicationId mobile, consumidores ativos e data de retirada. “App antigo” não é uma versão verificável; cada contrato precisa de intervalo de versões suportado.

| Domínio / cliente atual | Caminho observado | Autoridade durante coexistência | Estratégia de corte |
| --- | --- | --- | --- |
| Dashboard do painel | HTTP na API | Firestore até migrar o modelo de leitura | Preservar contrato HTTP; trocar repositório após reconciliação |
| Personalização do painel | Firestore direto, inclusive subscription de secrets no serviço de configuração | Firestore até a entrega vertical | Atualizar painel para API e remover dependência de secrets; bloquear escritor direto no tenant migrado |
| Configuração pública do Flutter | Leitura direta de configuração remota | Firestore canônico antes; projeção após corte | Aplicativos compatíveis continuam leitores; somente projetor escreve no documento depois do corte |
| Login/consultas SGP do Flutter | HTTP e autenticação Firebase com custom token | SGP para credencial/dados comerciais; Firebase para identidade | Manter contrato seguro e versões compatíveis; nenhuma permissão de token administrativo é transferida ao assinante |
| Perfil e dispositivo Flutter | Escrita direta em `clientes/{authUid}` | Firestore enquanto esse escritor existir | Atualizar app para API antes de cortar esse domínio, ou manter domínio legado; não declarar PostgreSQL canônico antecipadamente |
| Tickets Flutter | Comando em `function_requests`, leituras de documentos e anexos Storage | Handler legado até corte | Entrada de comando pode encaminhar ao novo caso de uso; bloquear escritas diretas em dados canônicos; manter autoria/tenant validados |
| Notificações/incidentes Flutter | Leitura direta de Firestore | Domínio legado ou projeção explicitamente versionada | Preservar consultas autorizadas/projeções até atualização do cliente; nunca fallback para tenant vizinho |
| Diagnósticos/histórico Flutter | HTTP, documentos diretos, fila de ticket e upload de relatório | Por recurso inventariado | Separar leitura, escrita e efeitos; migrar por contrato; usuário não altera diagnóstico alheio |
| Assets/anexos web/mobile | Upload/leitura direta Storage em parte dos fluxos | Objetos no Storage; autorização pelas regras | Paths e regras por tenant/recurso, teste de acesso por assinante/ticket e validade de URLs de download |
| Integrações e backups antigos | Painel/Functions/Firestore com permissões hoje amplas | Ponte privada gerida pelo SaaS após F1 | Nenhuma compatibilidade preserva acesso do provedor ao token ou a backup que o revele/altere |
| Builds | HTTP do builder e callable | Serviço existente, exclusivo SaaS | Aplicar mesmo controle em todos os pontos; manter continuidade de pacote/assinatura |
| `admin_app` e demais clientes legados | Inventário ainda incompleto | Não presumir | Bloquear corte do domínio afetado até classificar consumidores e decidir atualização/retirada |

Adapter HTTP preserva contrato HTTP. Ele **não intercepta uma escrita direta ao Firestore**. Para cada escrita direta, escolher e registrar uma destas opções antes do corte: atualizar o cliente; conservar aquele domínio sob autoridade antiga; ou criar entrada de comandos separada, validada e sem escrever o dado de negócio diretamente. Um trigger que espelha duas bases graváveis não estabelece escritor único.

### Sequência de autorização e sessão

| Etapa | Quem decide acesso | Como tratar consumidores existentes | Condição de avanço |
| --- | --- | --- | --- |
| A — Contenção do legado, F1 | Firebase Auth + controle de acesso legado verificável; papel e tenant explícitos | Regras/handlers consultam estado de bloqueio protegido; sessão Firebase continua nos SDKs; token/build negados ao provedor em todos os caminhos | Suspensão, papel removido, conta desativada e token antigo testados em HTTP, fila, Firestore e Storage |
| B — Primeiro domínio no PostgreSQL, F3/F4 | Mesmo controle da etapa A para identidade/permissão; PostgreSQL é autoridade apenas do domínio migrado | Vínculos podem ser copiados ao PostgreSQL para comparação, mas essa cópia não cria uma segunda decisão de acesso | Fluxo completo de configuração validado e escritor direto bloqueado |
| C — Transferência de memberships | PostgreSQL somente após remover acessos protegidos diretos da identidade afetada, ou validar ponte de bloqueio explícita | Consumidor residual sem essa ponte mantém a transferência de autorização adiada; fonte de dados e fonte de permissão não precisam mudar juntas | Todos os acessos residuais inventariados e revogação dentro do limite em falhas/retentativas |
| D — Sessão web própria | API valida sessão e memberships; Firebase mantém identidade externa | Ativar cookie opaco quando o painel não depender de SDK autenticado para recursos protegidos; mobile continua com token Firebase | Logout/revogação, CSRF, renovação e indisponibilidade externa testados; nenhuma sessão paralela esquecida |

Na etapa A, não basta mudar claims e esperar expiração. Implantar estado de acesso/revogação protegido de escrita por clientes e aplicado em todas as regras coincidentes e caminhos de servidor. Se o limite de 60 s abranger desativação externa, esse estado precisa de validade curta e renovação autenticada pelo backend: expiração/falha de renovação nega novos acessos. Validar suporte e custo em Firestore/Storage; se algum caminho não puder aplicar a política, removê-lo ou adiar a transição. O estado atual não oferece essa garantia universal.

A opção padrão para a primeira entrega é **adiar C e D**, evitando introduzir uma ponte distribuída de permissões antes de comprovar o domínio. Se uma ponte for indispensável depois, o ADR deve especificar bloqueio preventivo, versão monotônica, confirmação por destino, falha fechada e reconciliação. A API nega imediatamente a suspensão solicitada; a interface não anuncia suspensão integral enquanto existir acesso residual. Concessão de acesso nunca é aplicada em um lado por fallback quando o outro falha.

Logout local cancela listeners, limpa dados e encerra a sessão Firebase e/ou cookie aplicável. “Sair de todos os dispositivos” revoga as sessões de todos os caminhos; não confundir limpeza local com invalidação de um bearer token já emitido. Nenhuma revogação apaga dados já baixados; o teste verifica novos acessos e efeitos, incluindo listeners reconectados e jobs pendentes.

## 7. Operação no servidor único

O plano pode avançar no servidor atual, mas o host não ganha capacidade nem disponibilidade por mudar de arquitetura. Na medição anterior havia pressão de memória por outras aplicações. A fase 0 deve confirmar folga antes de criar processos permanentes.

### Controles obrigatórios

1. Medir CPU, RAM residente, swap, PSI, I/O, espaço/inodes, conexões PG e tráfego durante uso normal, push, sync e build.
2. Fazer orçamento agregado de serviços, incluindo sistema operacional e outras aplicações. Reserva Docker não cria RAM disponível. Não escolher limites finais por estimativa isolada de um container.
3. Manter banco, API e coordenação protegidos; build Android e speed test têm prioridade e concorrência menores. Adiar build quando os limites de pressão forem atingidos.
4. Desenvolver/testar com dados sintéticos e ambiente isolado de baixo consumo; não duplicar toda a produção no mesmo host sem folga comprovada. Executar verificações pesadas em sequência quando necessário.
5. Deixar banco e Redis sem exposição pública; separar redes, usuários, arquivos e credenciais. Não montar Docker socket no builder.
6. Limitar logs, artefatos, cache de build, filas mortas e históricos por política; alertar antes de esgotar disco.
7. Usar artefatos imutáveis, migrations explícitas, healthchecks e encerramento gracioso. Não executar migration destrutiva automaticamente na inicialização da API.

### Builds e assinatura

Dividir em pedido de build, executor restrito, assinatura e publicador. Cada fase tem permissões próprias. Conferir tenant, origem dos assets, checksum e metadados do artefato. A assinatura fica fora do ambiente que baixa/executa dependências de build.

Preservar keystore e continuidade de assinatura para permitir atualização dos aplicativos existentes. Publicar com manifesto contendo versão, commit, tenant, checksum e resultado de verificação da assinatura. Releases de teste não sobrescrevem o APK em produção.

Persistir applicationId único e estável por tenant, com constraint de unicidade e inventário dos pacotes já publicados. Não derivá-lo apenas removendo caracteres do ID. Artefatos têm caminho imutável por tenant/versão/build; um link estável de download aponta para uma versão já validada. Nunca trocar applicationId/keystore existente automaticamente para resolver colisão.

Preservar símbolos de ofuscação e mapeamentos aplicáveis por applicationId, versão, ABI e build, em armazenamento privado. Só limpar temporários após confirmar persistência/checksum dos artefatos exigidos. Teste de aceite recupera os símbolos depois da limpeza e simboliza uma falha controlada. Geração, repetição, cancelamento, assinatura e publicação são ações do SaaS; personalização do provedor não as autoriza.

Isolamento em containers no mesmo kernel reduz exposição, mas não equivale a máquina isolada. Se builds passarem a aceitar código arbitrário de terceiros, será necessário executor com isolamento mais forte antes de oferecer essa capacidade.

### Backup e desastre

Antes de tornar PostgreSQL a fonte principal, implantar backup base + arquivamento contínuo de WAL externo e comprovar PITR. Manter os backups atuais até concluir a transição e a retenção correspondente.

Na inspeção de 30/10/2026, `archive_mode=off` e `archive_timeout=0`; portanto o RPO de cinco minutos é uma meta, não uma capacidade atual. O ensaio de PITR deve incluir baixa atividade, falha do destino externo, atraso de upload e disco enchendo por WAL acumulado. Configurar fechamento periódico de segmentos ou mecanismo equivalente e medir a chegada efetiva do WAL fora do host; configuração isolada de `archive_timeout` não comprova o RPO. Não apagar WAL necessário como reação automática à falta de disco.

Ensaio inclui banco, objetos privados/públicos, identidades e configuração, chaves, versão de aplicação e recuperação de operações pendentes. Restaurar em namespace/projeto isolado, sem escrever no SGP, enviar push ou publicar APK real.

Documentar dependência de DNS, TLS, provisionamento de máquina, acesso ao provedor de identidade e chaves. Sem máquina de reposição disponível, o tempo de aquisição/provisionamento entra no RTO total e impede prometer recuperação física em poucas horas.

### Retomada após perda total de Redis

1. Bloquear dispatch/execução até estabelecer qual banco e qual geração de recuperação são válidos; não misturar fila velha com banco restaurado.
2. Recriar Redis de estado com persistência e `noeviction`; manter Redis de cache descartável separado.
3. Reconstruir operações elegíveis, agendas futuras e recorrentes a partir do PostgreSQL, respeitando cancelamento, versão, timezone, expiração e política de atraso.
4. Reconciliar operações com resultado externo desconhecido antes de repetição. Um lock perdido não prova que o efeito não ocorreu.
5. Testar tarefas futuras, lembretes expirados, cancelamento anterior à queda, recorrência, falha do dispatcher e ausência de duplicação de operações idempotentes. O teste atual de reconexão não atende a esse aceite.

### Retomada após PITR ou restauração de banco antigo

1. Restaurar isoladamente, com saída para SGP/FCM/publicação bloqueada, workers pausados e tráfego de usuários fechado.
2. Invalidar todas as sessões recuperadas e emitir nova geração de sessão; impedir que cookies ou tokens antigos reabram acesso pela API ou regras residuais.
3. Reconciliar bloqueios, perda de papel, cancelamentos e versões de credenciais posteriores ao instante restaurado. Usar diário de segurança externo ao banco restaurado e estado confiável do sistema de identidade; na falta de evidência, manter o acesso afetado negado até revisão da equipe SaaS. Autenticar novamente não prova que a permissão antiga continua válida.
4. Marcar como incertas operações que possam ter sido executadas no SGP, FCM, assinatura ou publicação depois do ponto recuperado. Consultar o upstream/registro externo e reutilizar chave de idempotência quando suportada. Sem comprovação, exigir reconciliação; não reenfileirar cegamente.
5. Reconstruir agendas apenas depois de reconciliar cancelamentos e ocorrências. Por padrão, não enviar em massa lembretes vencidos durante a indisponibilidade.
6. Verificar integridade, credenciais ativas, versões de app, objetos e projeções; reconstruir Redis/caches com geração nova. Reabrir leitura e depois mutações por domínio, com verificação registrada.

O diário externo de mudanças de acesso e efeitos sensíveis terá retenção, integridade e acesso separados do banco que pode voltar no tempo. Se a entrega desse diário falhar, a operação sensível correspondente deve permanecer bloqueada ou com estado inconclusivo documentado; ele não será apresentado como garantia de consistência sem teste. Restauração jamais reativa automaticamente uma versão de segredo revogada no SGP.

Aceite de recuperação inclui explicitamente: ação SGP executada antes da queda e conclusão perdida pelo PITR; administrador revogado depois do ponto restaurado; job futuro cancelado depois desse ponto; WAL com pouca atividade. O ensaio só termina quando a reabertura é segura, não quando o PostgreSQL inicia.

## 8. Metas e critérios de medição

São **metas de engenharia a validar**, não capacidade já entregue nem SLA contratual.

| Medida | Meta inicial / critério |
| --- | --- |
| Isolamento entre tenants | Zero acesso cruzado nos testes de API, SQL/RLS, cache, arquivos, fila e migração; qualquer ocorrência bloqueia avanço |
| Integridade de migração | 100% dos registros do escopo contabilizados como migrados, excluídos por regra explícita ou em exceção resolvida; sem órfãos inesperados |
| API de dashboard local, após autenticação | p95 ≤ 300 ms e p99 ≤ 800 ms na carga homologada, distinguindo cache frio/quente |
| Restauração de sessão até dados essenciais | p95 ≤ 1,5 s no perfil de rede/dispositivo de referência |
| Clique em Entrar até dados essenciais | p95 ≤ 2,5 s no mesmo perfil; dependência de identidade medida separadamente |
| Leituras locais paginadas | p95 ≤ 300 ms; tamanho máximo e plano de consulta verificados |
| Sucesso das jornadas | ≥ 99,5% na janela definida; exclusões e falhas de dependência publicadas separadamente, sem mascarar erro como dado vazio |
| Sincronização SGP normal | atraso p95 ≤ 15 min como hipótese inicial; ajustar ao volume e cota real de cada integração |
| Atualização de configuração publicada | disponível aos clientes compatíveis em até 60 s em condição normal |
| Revogação de acesso | propagação máxima de 60 s em todos os caminhos suportados; indisponibilidade externa segue a política da seção 5; ações sensíveis com checagem atualizada |
| Outbox e operações | pendências recuperadas após falha; alerta se idade exceder 60 s no fluxo normal, excluindo adiamento explícito |
| Backup PostgreSQL após mudança | objetivo RPO ≤ 5 min, com WAL externo confirmado e ensaio também sob baixa atividade; estado atual não atende |
| Recuperação lógica | objetivo RTO ≤ 4 h com destino já provisionado; medir separadamente a reposição física |

Definir na fase 0 os perfis desktop/mobile, localização, latência, dispositivo, volume e janela de medição. Percentil com poucas amostras não é evidência de aceite. Segmentar login/restauração, SaaS/provedor, sucesso/falha e dependências. Telemetria de erro precisa existir mesmo quando o dashboard não termina de carregar.

Carga inicial de laboratório: 20 tenants, 100 mil assinantes, múltiplos contratos, distribuição desigual e cenários de cache frio/quente. Degraus sugeridos: 25, 50, 100 e 200 usuários virtuais, com pausas e jornadas definidas. Usuário virtual não equivale a requisição simultânea nem a usuário cadastrado. A carga homologada será o maior patamar que cumprir os critérios, com margem registrada; os demais patamares servem para encontrar limites.

Testar SGP de 50 ms, 500 ms e 2 s, indisponível, dados inconsistentes e respostas grandes; rajada após push; um tenant concentrando carga; sincronização simultânea; build ativo; perda/reinício de worker, Redis e API. Gerador de carga separado quando possível; se compartilhar CPU com o sistema, registrar a distorção. Carga pesada contra o SGP real exige janela e limites específicos.

## 9. Fases de execução

Todas as fases estão **pendentes**. Uma fase só termina com código/infraestrutura aplicáveis, verificações e evidências vinculadas. Não marcar uma fase inteira como concluída porque apenas seu esqueleto existe.

### Gates de passagem e primeira entrega

| Gate | Evidência exigida | Libera |
| --- | --- | --- |
| G0 — Baseline rastreável | Matriz C1–C16/E1–E9, revisão Git, diferenças, versões de regras/artefatos, ferramentas e consumidores | Trabalho delimitado e verificável |
| G1 — Fronteiras de segurança | P0 locais resolvidos/testados/implantados; provedor sem token/build por nenhum caminho; riscos externos registrados com responsável e mitigação | Piloto de dados, depois de G2 |
| G2 — Fundação mínima recuperável | RLS, único escritor, outbox limitada ao domínio, rollback e PITR ensaiados; compatibilidade de autorização validada | Primeira entrega vertical de configuração |
| G3 — Piloto por domínio | Configuração ponta a ponta observada, sem divergência, segredo exposto ou escrita antiga residual | Reutilizar padrões nos próximos domínios |
| G4 — Homologação integrada | Fases aplicáveis concluídas, jornadas de vários domínios, carga e desastre completos | Expansão por lotes e retirada do legado |

Dependência externa aberta não recebe status de correção. E8 exige registro de mitigação e decisão explícita de risco da operação SaaS antes de avançar; isso não autoriza ignorar falhas P0 locais que podem ser corrigidas agora. Falhas P1 bloqueiam a entrega afetada. A infraestrutura genérica deve crescer a partir de G3, não antecipar todos os módulos na fase 2.

**Primeira entrega completa, na fase 4:** provedor autenticado altera cor/texto/logo permitidos → API valida papel/tenant/schema → PostgreSQL grava configuração/versionamento e outbox na mesma transação → worker atualiza projeção pública sanitizada → aplicativo das versões suportadas apresenta a configuração. SaaS e provedor autorizado consultam a trilha permitida e restauram uma versão de personalização dentro de seu escopo. O provedor não obtém token nem dispara build em nenhum ponto.

**Pré-requisitos:** G0–G2; aplicação da nova matriz de permissões também no legado; segredo existente preservado; teste de tenant A/B e credencial ausente nas projeções/backups; atraso e duplicação de evento tolerados; bloqueio de escrita antiga; recuperação do banco e retorno após novas escritas ensaiados. A autoridade de identidade pode continuar no Firebase conforme etapa B da seção 6.

**Fora do pré-requisito desse piloto:** troca completa para Fastify, cookie opaco, migração total de memberships, tickets/campanhas/dispositivos, reconstrução completa do builder e outro servidor. As falhas de segurança desses componentes já expostos continuam sujeitas a G1; não são adiadas só porque não fazem parte da configuração.

**Aceite G3:** alteração e restauração com campos excluídos corretamente; duas edições concorrentes sem sobrescrita silenciosa; interrupção após commit e antes da projeção recuperada; versões antigas não sobrescrevem novas; token/build negados por interface e chamadas forjadas; versões mobile suportadas verificadas; observação por pelo menos sete dias incluindo backup diário. A fase 8 é o piloto integrado posterior, não a primeira validação do novo desenho.

### Registro do lote 1 F0/F1 (31/10/2026)

**Escopo:** baseline rastreável e inventário mínimo de configuração/segredos/backups/builds para C4, C11, E3 e E9, mais registro do backlog e da ordem de implantação/rollback. Documentação apenas: [inventário](operations/rearchitecture-f0-f1-inventory-2026-10-31.md). Baseline vinculado: `aeef740` (alterações locais anteriores preservadas, **não** é correção nova) e `608af5f` (manifesto observado de implantação, **não** é homologação nem prova de equivalência). Responsável técnico nominal desta continuação: `executor-codex-task-17baa3af4fe4-f0-baseline` (identificado no `summary` do `.paseo-result.json`; revisão independente posterior pelo controlador); coordenação: gerente do chat; E8: administrador externo do SGP. Rascunho anterior preservado e complementado por conferência estática das fontes; nenhum código de produto alterado.

**Testes:** `git diff --check` (único teste obrigatório; resultado no fim desta seção). Testes de regras não executados: Java 17 do host é incompatível com o CLI (exige Java 21); é necessário ambiente isolado Java 21. Nenhum teste de aplicação foi executado porque nenhum código mudou.

| Item | Código | Testado | Implantado | Distribuído |
| --- | --- | --- | --- | --- |
| Inventário C4/C11/E3/E9 (arquivo/rota/efeito/autorização) | documentado | `git diff --check` | não | não |
| Correções C4/C11/E3/E9 | não implementadas | não | não | não |

**Estado das fases:** F0 e G0 permanecem **incompletos** (faltam inventário de dados por tenant, IAM real, versões mobile/`admin_app` e custo). F1 não iniciou correções neste lote; as caixas das fases abaixo não foram marcadas. Principais lacunas e continuações constam no inventário (seções 4 e 5). Nenhuma implantação, push ou alteração de serviço/segredo foi feita.

**Resultado real da validação documental (31/10/2026):** `git diff --check` — aprovado, exit 0, uma rodada essencial ao fim do bloco. Leitura estática conferiu fachadas do `Caddyfile`, API/consumidor `admin_app`, permissões RPC, backups, callables, regras e consumidores de configuração/anexos do `unified`; não é teste funcional de autorização. Manifestos de baseline reutilizados, sem nova coleta operacional. Backlog nominal, dependências e riscos no inventário, seção 5; sequência de implantação/rollback na seção 7 inclui atualização dos clientes antes de restringir regras, sem preservar acesso indevido a segredos.

### Fase 0 — Inventário, contratos e linha de base

**Dependência:** nenhuma. **Prioridade:** imediata.

- [ ] Registrar revisão do código, alterações locais e artefatos em produção; preservar o trabalho existente sem reset ou limpeza destrutiva. Preparar commits revisáveis e manifesto que relacione commit, testes, imagens, regras, Functions e APK, sem incluir segredos.
- [ ] Inventariar rotas, Functions, coleções, buckets, usuários de serviço, jobs, cron, scripts e consumidores mobile/web, incluindo `admin_app` e legados.
- [ ] Construir matriz de funcionalidades: fluxo, consumidor, contrato, autorização, fonte de dados, efeito externo e teste de regressão.
- [ ] Inventariar volume/qualidade de dados por tenant; separar duplicados, múltiplos contratos, perfis legados e dados sem vínculo verificável.
- [ ] Medir experiência de login/restauração e dependências; persistir métricas agregadas sem segredos/PII desnecessária.
- [ ] Medir host e definir orçamento para migração, ambiente de teste, observabilidade e operação final.
- [ ] Criar ADRs de arquitetura, autoridade dos dados, tenancy/RLS, sessão/revogação, outbox, compatibilidade mobile e recuperação.
- [ ] Definir backlog por domínio e acompanhar fase, responsável técnico, evidência, risco e próximo passo.
- [ ] Completar a matriz C1–C16/E1–E9 e atribuir responsáveis; arquivar logs sanitizados com comandos, versões, resultados e limites, sem tratar `/tmp` como arquivo permanente de evidências.
- [ ] Fixar ambiente reproduzível de validação: Node, Java compatível com emuladores, Firebase CLI, Flutter, dependências e imagens. Resolver a incompatibilidade Java/CLI observada antes de aceitar novos resultados de regras.
- [ ] Inventariar aplicação/versão/tenant dos clientes suportados, pacotes Android, símbolos, contratos de acesso direto e canais de distribuição; documentar o que ainda não pôde ser identificado.
- [ ] Detalhar custo/IAM do Secret Manager, custo da verificação de acesso e estratégia de diário externo/recuperação antes de ativar essas dependências.

**Aceite G0:** mapa verificável de consumidores e fontes de verdade; matriz inicial com evidências e lacunas; artefatos rastreáveis; ambiente de teste sem efeitos externos; linha de base e orçamento registrados. Não atribuir às correções locais o commit antigo como se ele as contivesse.

### Fase 1 — Fechar falhas remanescentes no sistema atual

**Dependência:** inventário mínimo da fase 0. **Prioridade:** imediata; não aguardar o novo backend.

- [ ] Fechar escrita/leitura aninhada de credenciais em todas as rotas públicas de configuração, incluindo o POST de provedores e sua auditoria.
- [ ] Testar payloads aninhados, campos desconhecidos e respostas de todos os perfis, usando segredos sintéticos.
- [ ] Corrigir distinção entre lock duplicado e falha transitória; implementar lease/reentrada e tratamento de requisições órfãs no RPC legado enquanto permanecer ativo.
- [ ] Diferenciar operações seguras de repetir e efeitos externos incertos durante recuperação de locks; não reexecutar mutações sem reconciliação.
- [ ] Substituir indicadores, séries, tendências e badges inventados por N/D ou medida verificável; exibir erro em vez de zero quando a consulta falhar.
- [ ] Retirar a credencial administrativa do ambiente de build e estabelecer identidades mínimas por serviço, validando os fluxos existentes antes de revogar acessos antigos.
- [ ] Preparar rotação de segredo SGP, mantendo-a identificada como dependência externa.
- [ ] Aplicar E3: somente SaaS cadastra/altera integração e gera apps. Separar formulário de personalização, retirar leitura de secrets pelo provedor e bloquear rotas, callables, fila, backups e wildcards que contornem a decisão.
- [ ] Fechar C5/C6: política compartilhada de saída SGP, destino efetivamente validado e ausência de fallback cruzado; rejeitar URL/token/app arbitrários em endpoints de uso do provedor/assinante.
- [ ] Completar testes C1/C2/C3: papéis emitidos no login real, senha obrigatória, versões antigas, IDs conflitantes, dados históricos e acessos diretos; nenhum fechamento apenas por teste de helper.
- [ ] Fechar os comportamentos imediatos de C7/C9/C10/C15: conclusão terminal, erro de fatura, notificações próprias e contagem filtrada, com testes específicos.
- [ ] Corrigir C11: definir escopo e restore exato de personalização; impedir restauração de credencial por provedor, inclusive em backups antigos.
- [ ] Conter C12/C13 antes de novos builds afetados: detectar conflito de pacote/nome, impedir sobrescrita e preservar símbolos antes de limpar temporários.
- [ ] Corrigir C14: eliminar falso envio comercial; contato explícito ou destino real validado, sem registrar sucesso artificial.
- [ ] Tratar C16/E1/E9: autorização do speed test, medidas/diagnósticos simulados, rota 501, caminhos fora da fachada e escopo de anexos por usuário/recurso.
- [ ] Implantar bloqueio/revogação coerente do legado e testar jobs já enfileirados, listeners reconectados e tokens anteriores à remoção de papel.

**Aceite G1:** testes de regressão da exposição e da autorização em todos os transportes; segredo privado preservado; provedor sem acesso a token/geração; build e integração funcionais; recuperação de requisição interrompida demonstrada; dashboard/formulário sem sucesso ou medidas fabricados. Cada achado recebe evidência ou continuação de fase explícita; nenhum P0 local aberto é disfarçado como refatoração futura.

### Fase 2 — Fundação do backend e recuperação PostgreSQL

**Dependência:** fases 0 e 1; pode haver trabalho preparatório em paralelo sem mudar autoridade de dados.

- [ ] Registrar ADR e comparação de uma rota para Fastify. Introduzi-lo se o benefício justificar o custo; manter Express no piloto caso a troca atrase a entrega. Preservar contratos legados.
- [ ] Criar somente módulos e infraestrutura necessários à primeira entrega: configuração validada, schemas/OpenAPI, erros, correlação e cliente tipado.
- [ ] Criar migrations SQL, usuários de banco separados, constraints, contexto de tenant e RLS.
- [ ] Implementar a primeira operação/outbox/dispatcher para configuração e mecanismos de idempotência/reconciliação necessários. Estabelecer contrato durável de agendas para os workers que serão migrados, sem construir antecipadamente todos os domínios.
- [ ] Implementar logs/métricas/traces com redaction e retenção; readiness distingue dependência essencial e opcional.
- [ ] Preparar WAL externo, backup base e restauração PITR isolada, incluindo pouca atividade e bloqueio de reabertura insegura, medindo RPO/RTO antes do primeiro domínio canônico no PostgreSQL.
- [ ] Criar pipeline de build/teste, migrations compatíveis, imagens imutáveis e deploy por módulo/tenant.

**Aceite técnico para G2:** backend serve o fluxo de configuração em teste; RLS impede cruzamento até com conexão reutilizada; commit/outbox/job sobrevive a falhas; banco recuperado de backup e WAL; nenhum domínio real muda de escritor nesta fase. G2 também exige a compatibilidade de acesso da fase 3.

### Fase 3 — Tenants e autorização de transição

**Dependência:** fase 2.

- [ ] Importar provedores/identidades para UUIDs e referências, preservando UID Firebase e mapeamentos legados.
- [ ] Preparar memberships e comparação, autorização por caso de uso, políticas globais e suspensão; manter autoridade de acesso legada nas etapas A/B da seção 6.
- [ ] Implementar/validar MFA administrativo conforme suporte e política de indisponibilidade. Preparar contrato de sessão web, CSRF, renovação e logout; ativação do cookie opaco depende do gate D, não do término desta fase.
- [ ] Manter autenticação mobile atual e introduzir autorização local compatível, sem trocar a senha central do SGP.
- [ ] Fazer reconciliação de permissões durante transição; promover PostgreSQL como autoridade do vínculo apenas no gate C. Na primeira entrega, a cópia de memberships não autoriza por conta própria.
- [ ] Comparar acessos permitidos/negados com a política anterior e testar perda de papel, conta desativada, múltiplos vínculos e logout entre abas.

**Aceite de acesso para G2:** SaaS/provedor/assinante funcionam nos clientes suportados; provedor não acessa token/build; zero elevação ou acesso cruzado; revogação e indisponibilidade testadas no legado e API; login/restauração medidos sem enfraquecer a checagem de conta. Registrar expressamente que gates C/D ainda estão adiados quando aplicável.

### Fase 4 — Provedores, configuração e segredos

**Dependência:** fase 3.

- [ ] Migrar cadastro/configuração para PostgreSQL com versões e controle de concorrência.
- [ ] Publicar documento/projeção somente de campos públicos necessários aos APKs antigos, a partir da fonte canônica e via outbox.
- [ ] Migrar painel de configuração para API; bloquear o escritor antigo apenas no escopo já migrado.
- [ ] Implementar serviço privado de credenciais, versão candidata/testada/ativa, endpoint exclusivo SaaS e identidades mínimas; usar ponte privada restrita enquanto o Secret Manager não for validado.
- [ ] Reconciliar assets, backups/restauração de configuração, tema/layout, menus e flags em todos os layouts suportados.
- [ ] Executar o piloto vertical definido em G3, incluindo versões mobile suportadas, falha de projeção, restore exato, teste negativo de token/build e observação.

**Aceite G3:** criar, editar, publicar e restaurar personalização no provedor piloto; app compatível recebe projeção correta; credenciais ausentes em saída pública, backup de personalização e logs; único escritor e atraso da projeção observável; geração de binário continua exclusiva do SaaS. Os próximos domínios reutilizam apenas os padrões comprovados nessa entrega.

### Fase 5 — Adapter SGP e projeções de assinantes

**Dependência:** fases 2–4.

- [ ] Consolidar normalização, credenciais, timeout, limites, circuito e cache em um único adapter usado por API/workers.
- [ ] Implementar sincronização incremental quando suportada e reconciliação completa periódica; paginação por offset do SGP não será presumida como snapshot estável.
- [ ] Usar geração/checkpoint para detectar repetição, alterações entre páginas, remoções e término incompleto. Ausência em sync parcial não apaga cliente.
- [ ] Gravar projeções locais e intenção de compatibilidade na mesma transação; retirar dual-write direto PostgreSQL/Firestore.
- [ ] Migrar assinantes, contratos e dispositivos com referências corretas; resolver dados históricos sem apagar documentos por divergência de contagem.
- [ ] Expor listagem/detalhes via API com busca paginada, filtros indexados e timestamps de atualização.
- [ ] Implementar estados de comando SGP e reconciliação para resultado desconhecido; manter ações sensíveis no upstream.
- [ ] Encerrar C3/C6/C7 no escopo migrado com testes de colisão, ausência de segredo, falha entre persistências, cancelamento e versão antiga de sync; anexar relatório de reconciliação histórica.

**Aceite:** conjunto sintético de 100 mil assinantes consistente, piloto real reconciliado, retomada após falha sem sobrescrita antiga, zero cruzamento e taxa upstream limitada. Leituras locais continuam disponíveis durante falha SGP, com atualização indicada.

### Fase 6 — Tickets, notificações e dashboards

**Dependência:** fases 3–5 para os respectivos dados consumidos.

- [ ] Migrar tickets, mensagens, anexos e estados, com ordem e autoria preservadas.
- [ ] Migrar campanhas/lembretes/dispositivos; implementar preferências, tentativas, deduplicação e definição de horários.
- [ ] Implementar modelos locais de leitura do dashboard e agregações incrementais/reconciliáveis; não consultar todas as contas/contratos no login.
- [ ] Definir catálogo de indicadores com fórmula, origem, janela, limitações e critérios para N/D.
- [ ] Atualizar telas para estados de erro/parcial/desatualizado e instrumentação de falha.
- [ ] Publicar eventos mínimos de atividade no app quando houver finalidade definida; não chamar cadastro de dispositivo de instalação medida.
- [ ] Retirar `function_requests` e acessos diretos de cada fluxo já migrado, mantendo adapters necessários aos clientes antigos.
- [ ] Encerrar C9/C10/C15/E1 com cenários reais de tela e dados sintéticos; acesso a informação do app não concede ao provedor privilégios de integração.
- [ ] Persistir agendas futuras/cancelamentos e testar reconstrução após perda total de Redis, não apenas reconexão.

**Aceite:** jornadas completas de tickets/push/dashboard por perfil; números conciliados com a definição; falha não vira zero; metas de consulta e renderização medidas com cache frio/quente e dados de todos os tenants.

### Fase 7 — Builds, assinatura, APK e serviços auxiliares

**Dependência:** fases 2–4; redução imediata de privilégios já pertence à fase 1.

- [ ] Migrar estados de build para operações duráveis e ligar executor, assinatura e publicação por contratos restritos.
- [ ] Implantar ambiente de build sem credenciais administrativas, com permissões de filesystem/rede e saída limitadas ao necessário.
- [ ] Manter assinatura isolada, continuidade da keystore, checksum e trilha de artefatos.
- [ ] Encerrar C12/C13: applicationId persistido/único, caminhos imutáveis, símbolos privados recuperáveis e simbolização de falha após limpeza dos temporários.
- [ ] Verificar que somente SaaS pode iniciar/repetir/cancelar build e assinar/publicar, incluindo callable, HTTP direto, fila e jobs enfileirados antes da revogação; exibir ao provedor apenas versão/link público.
- [ ] Condicionar execução a orçamento de CPU/RAM/disco; manter fila de um build por vez enquanto as medições não justificarem ampliar.
- [ ] Preservar limites e comunicação correta do speed test; medir concorrência com API, backup e build.
- [ ] Preparar configuração para mover build/speed test a outro host futuramente, sem tornar essa mudança física pré-requisito para as etapas anteriores.

**Aceite:** APK novo atualiza o existente com mesma assinatura, login e configurações funcionam, builder não acessa dados administrativos, interrupção tem estado recuperável e não há publicação incompleta.

### Fase 8 — Homologação e piloto integrado de produção

**Dependência:** fases 1–7 para todo o escopo do piloto.

Esta fase integra os domínios já validados individualmente. Ela não posterga o primeiro piloto de configuração da fase 4. Os gates C/D de autorização/sessão podem ser concluídos aqui ou antes, apenas quando seus consumidores e testes estiverem atendidos.

- [ ] Executar jornadas web/mobile, testes de autorização/RLS, migração, carga, falha e recuperação.
- [ ] Executar PITR e recuperação integral isolada, incluindo identidade, arquivos, filas reconstruídas e versão correta da aplicação.
- [ ] Ensaiar ação SGP concluída mas perdida no ponto restaurado, papel revogado após esse ponto, sessão antiga, token upstream revogado e agenda futura cancelada; comprovar bloqueio até reconciliação.
- [ ] Validar política de indisponibilidade de revogação com identidade fora do ar, cache vencido e tentativas pelos SDKs legados; incluir falhas no indicador de disponibilidade.
- [ ] Comparar leituras antigas/novas no modo sombra, sem repetir mutações externas nem disparar notificações.
- [ ] Ativar um tenant piloto e acompanhar pelo menos sete dias, incluindo ciclo de lembrete, sincronização, backup e build controlado.
- [ ] Registrar p50/p95/p99, taxa de erro, 429/503, frescor dos dados, idade de fila/outbox, limites de recursos e divergências.
- [ ] Corrigir desvios antes de ampliar; falta de volume para comprovar percentis deve ser complementada por laboratório e identificada no relatório.

**Aceite:** nenhuma divergência relevante sem explicação; metas cumpridas na carga homologada; sem incidente de isolamento; restauração e reversão ensaiadas; relatório de capacidade descreve recursos e dependências reais.

### Fase 9 — Expansão e retirada do legado

**Dependência:** aceite do piloto.

- [ ] Expandir por lotes de tenants com pontos de controle e possibilidade de interromper avanço por tenant.
- [ ] Acompanhar versões móveis ativas; publicar atualização e plano de compatibilidade antes de bloquear contrato antigo.
- [ ] Retirar tráfego e escrita legados somente após comprovar ausência de consumidores suportados e reprocessamentos pendentes.
- [ ] Desligar triggers/RPC/rotas duplicadas, regras de acesso direto e projeções sem consumidor; exportar o histórico necessário antes da retenção/remoção.
- [ ] Revogar credenciais antigas, retirar dependências, arquivos e serviços sem uso, sem apagar keystores ou backups necessários à recuperação.
- [ ] Atualizar `docs/architecture.md`, contratos, runbooks, configuração de deploy, alertas e custos da arquitetura final.
- [ ] Concluir gates C/D quando ainda pendentes e retirar os controles/projeções temporários somente após comprovar que não há consumidor protegido residual.
- [ ] Publicar matriz final de achados encerrados e pendências externas, com manifestos e evidências de distribuição; nenhum C1–C16/E1–E9 desaparece por desligamento sem verificação dos consumidores.

**Aceite:** arquitetura documentada corresponde à produção; uma única trilha de escrita por domínio; zero consumidor suportado dependente do RPC antigo; recuperação e observabilidade funcionam após desligar o legado.

## 10. Procedimento de migração e retorno por domínio

Cada domínio terá um registro de migração com: tenant, origem, destino, escritor ativo, versão do schema, checkpoint, divergências, evidências, horário de corte e estratégia de retorno.

Acrescentar a esse registro: versões de cliente admitidas, todos os caminhos diretos, autoridade de autorização, situação dos gates C/D, direitos SaaS/provedor e caminho de revogação. Nenhum corte de personalização pode reabrir ao provedor o acesso a token, destino SGP, build ou backup misto.

1. **Preparar:** backup verificado, schema expansivo, mapeamentos, adapters e flag de roteamento por tenant/domínio. Migração não depende de alteração manual sem registro.
2. **Copiar:** leitura paginada da origem ainda canônica; transformação determinística e upsert retomável. Não copiar segredos para projeções públicas.
3. **Capturar mudanças:** manter diário durável de alterações posteriores ao checkpoint. Triggers antigos são pelo menos uma vez e podem chegar fora de ordem; usar versão e reconciliação. Se não houver captura confiável, fazer pausa curta de escrita no corte. Captura de mudanças auxilia a migração, não legitima dois escritores depois do corte.
4. **Reconciliar:** contagem por categoria, IDs, vínculos, campos relevantes, somas quando aplicável e anexos; listar exceções e resolver divergências.
5. **Comparar:** leituras sombra novas/antigas sem duplicar efeitos externos. O aplicativo continua escrevendo apenas na autoridade antiga.
6. **Cortar:** pausar escrita do escopo, drenar operações, aplicar delta final, validar, trocar escritor/rotas e bloquear a escrita anterior. Invalidar caches e registrar watermark do corte.
7. **Observar:** publicar projeções de compatibilidade por outbox, acompanhar atraso/falhas e manter o legado somente leitura no escopo migrado.
8. **Retirar:** encerrar compatibilidade apenas depois dos critérios de clientes, estabilidade, retenção e recuperação.

### O que significa rollback

**Antes do corte de escrita**, voltar a leitura ao legado é simples: ele ainda é a autoridade.

**Depois que o PostgreSQL recebe novas escritas**, uma flag não basta. Primeiro interromper novas mutações do domínio; exportar/reproduzir o delta canônico em processo idempotente, reconciliar a fonte anterior, invalidar caches e só então reativá-la. Efeitos externos já ocorridos não são desfeitos por restaurar um banco.

Quando a reversão dos dados não for segura, usar correção para frente ou modo de leitura temporário. Reverter versão da aplicação exige schema compatível com ambos os binários; alterações seguem expandir, migrar e só depois remover. Não restaurar backup antigo sobre produção para desfazer deploy comum.

Interrompem a expansão: qualquer acesso cruzado, vazamento de segredo, perda/duplicação de mutação crítica, divergência não explicada, backup inválido ou violação persistente das metas no patamar homologado. Sobrecarga controlada fora desse patamar deve ser registrada como limite, sem ampliar o produto além dele.

## 11. Organização sugerida do repositório

O destino lógico abaixo pode ser alcançado mantendo os diretórios atuais durante a transição. Mover pastas não deve ser um pré-requisito artificial para corrigir o sistema.

```text
admin-painel/                 # React; contratos HTTP e componentes
app-flutter/unified/          # aplicativo mobile canônico
api-service/
  src/modules/               # casos de uso e fronteiras por domínio
  src/http/                  # schemas e adapters; Fastify conforme ADR
  src/infrastructure/        # PostgreSQL, Redis, identidade, Storage
  src/workers/               # entradas de workers usando os mesmos módulos
shared/
  contracts/                 # contratos públicos versionados
  runtime/                   # apenas componentes compartilhados necessários
services/
  apk-builder/               # execução restrita
  apk-signer/                # assinatura restrita, a criar
scripts/migrations/          # dados, checkpoints e reconciliação
scripts/ops/                 # deploy, recuperação e verificações
docs/adr/                    # decisões com consequências
docs/contracts/              # OpenAPI, eventos e compatibilidade
docs/operations/             # runbooks e evidências de aceite
```

`functions` e `proxy-sgp` permanecem enquanto houver consumidor ou responsabilidade não migrada. Seu desligamento precisa de evidência; não serão simplesmente renomeados e considerados resolvidos.

## 12. Estimativa, dependências e riscos

Faixa preliminar da primeira revisão para **uma pessoa experiente dedicada**, incluindo testes e documentação. Os achados e controles explicitados nesta revisão exigem reestimativa; a tabela não foi validada por execução da fase 0 e não constitui compromisso de prazo:

| Bloco | Esforço indicativo |
| --- | --- |
| Fases 0–1: inventário e correções remanescentes | 1–2 semanas |
| Fase 2: fundação, outbox, RLS e recuperação | 2–3 semanas |
| Fases 3–4: acesso, tenants e configuração | 2–4 semanas |
| Fase 5: SGP, assinantes e consistência | 2–4 semanas |
| Fases 6–7: demais domínios, clientes e builds | 3–5 semanas |
| Fases 8–9: homologação, piloto e expansão | 2–4 semanas, incluindo observação |
| **Faixa preliminar anterior, a reestimar** | **12–22 semanas** |

Reestimar depois do inventário e do primeiro domínio migrado, incluindo explicitamente C1–C16/E1–E9 e a mudança de autorização SaaS/provedor. Dados inconsistentes, compatibilidade móvel, acesso ao SGP e recursos do host podem ampliar o calendário. Automação de código não substitui a espera por ciclo operacional nem comprova comportamento em produção.

### O que pode avançar agora

- Inventário, correções de segurança e indicadores, contratos, módulos, banco/RLS, outbox, migrações de teste, interface por API e ensaios com dados sintéticos.
- Redução de privilégios, budgets, backup/WAL e preparação da compatibilidade, usando os serviços e acesso existentes.
- Piloto no host atual somente com capacidade medida e etapas compatíveis com sua folga. Se não houver recursos para rodar API nova e antiga simultaneamente, usar testes sequenciais e corte com manutenção; não forçar implantação concorrente.

### O que depende de acesso ou infraestrutura externa

| Dependência | Consequência | Ação enquanto indisponível |
| --- | --- | --- |
| Administração do SGP | Rotação do token exposto e ajustes de cota/recursos upstream | Preparar troca validada; preservar segredo privado operacional |
| Capacidade livre comprovada no host | Ambiente simultâneo e determinadas etapas de homologação | Medir, limitar serviços próprios e executar em sequência; registrar eventual bloqueio concreto |
| Plano/capacidade do serviço de identidade | Método de MFA e custos associados | Validar suporte; não desenvolver autenticação própria como atalho |
| Outra máquina ou serviço gerenciado | Alta disponibilidade física e isolamento mais forte | Preparar configuração portátil; manter limitação explícita |
| Acesso às lojas e distribuição mobile | Adoção de contrato novo e retirada do antigo | Preservar compatibilidade; acompanhar versões e preparar release assinado |

### Riscos principais e resposta

- **Perda de dado na migração:** checkpoint, delta, reconciliação e corte com único escritor.
- **Retorno ao legado desatualizado:** plano por domínio com reprodução do delta, não apenas flag.
- **Pressão de memória/disco:** orçamento agregado, observação e adiamento de trabalhos auxiliares.
- **Dependência de SGP lento/instável:** projeção local, circuito, cotas e estado explícito de atualização.
- **Token/cookie/chave em logs ou artefatos:** schemas, redaction, permissões e testes com segredos sintéticos.
- **Permissão antiga persistente:** memberships, invalidação, política de revogação e teste de conta desativada.
- **Aplicativos antigos escrevendo na origem anterior:** adapter compatível, bloqueio de escrita no escopo migrado e telemetria por versão.
- **Operação PostgreSQL negligenciada:** WAL externo e restauração comprovados antes da troca de autoridade.
- **Complexidade excessiva:** monólito modular; cada serviço ou dependência nova precisa resolver um problema demonstrável.
- **SaaS/provedor separados apenas na tela:** negar token/build e destinos internos também no backend, regras, backups, jobs e identidades de serviço; testar chamadas forjadas.
- **Sessão própria sem controle do SDK legado:** adiar gates C/D até provar suspensão/logout/revogação em todos os caminhos, mantendo uma autoridade de acesso por etapa.
- **PITR reativa privilégio ou repete efeito:** quarentena, invalidação de sessões, diário externo e reconciliação antes de abrir acesso/execução.

## 13. Definição de conclusão

A rearquitetura estará concluída quando:

- [ ] Todo o escopo funcional inventariado estiver atendido e as jornadas críticas passarem nos clientes suportados.
- [ ] C1–C16/E1–E9 tiverem encerramento com commit, teste e manifesto de implantação, ou dependência externa explicitamente aberta, com responsável e mitigação.
- [ ] Somente o administrativo SaaS puder cadastrar/trocar token e gerir geração/assinatura/publicação; o provedor operar personalização/informações sem acesso indireto a essas capacidades.
- [ ] Domínios próprios tiverem PostgreSQL como autoridade; SGP e identidade externa mantiverem suas responsabilidades definidas.
- [ ] Não houver dual-write direto sem transação/outbox, nem dependência ativa de RPC por documentos para operações migradas.
- [ ] Tenancy, RLS, revogação, segredos, arquivos e builds tiverem isolamento demonstrado.
- [ ] Indicadores representarem medidas verificáveis, com origem e atualização claras.
- [ ] Metas de latência, capacidade e frescor tiverem relatório reproduzível com limites explícitos.
- [ ] Backups, PITR e recuperação integral tiverem ensaio concluído e tempos medidos.
- [ ] Recuperação incluir agendas futuras/canceladas, sessões, revogações posteriores ao ponto restaurado e efeitos externos possivelmente já executados.
- [ ] Aplicativos existentes mantiverem continuidade de identidade, configuração e assinatura.
- [ ] Artefatos imutáveis, applicationIds únicos e símbolos de ofuscação preservados tiverem testes verificáveis, inclusive após limpeza do build.
- [ ] Legado sem consumidor for retirado, documentação corresponder à implantação e custos forem conhecidos.
- [ ] Pendências externas restantes, como rotação SGP ou ausência de alta disponibilidade, estiverem registradas sem serem apresentadas como resolvidas.

O primeiro lote de execução é **fases 0 e 1**. Nenhuma reescrita ampla deve preceder o inventário mínimo, o fechamento das falhas remanescentes e a definição de quem escreve cada dado.

## 14. Referências e relação com os documentos anteriores

Este plano substitui a direção arquitetural anterior **para o novo trabalho**, preservando a história do [plano de julho](plano-refatoracao-completa.md) e de sua [conclusão](refactor-completion-2026-07-10.md). Esses documentos descrevem outro escopo; não devem ser usados como prova de conclusão das etapas aqui propostas. `docs/architecture.md` continua descrevendo a implantação atual até ser atualizado por cada entrega efetiva.

Referências primárias consultadas em 30/10/2026:

- [PostgreSQL — Row Security Policies](https://www.postgresql.org/docs/current/ddl-rowsecurity.html): RLS complementa privilégios; donos/superusers e papéis com bypass exigem atenção no desenho das conexões.
- [PostgreSQL — Continuous Archiving and PITR](https://www.postgresql.org/docs/current/continuous-archiving.html): backup base e WAL formam a base da recuperação até um ponto no tempo.
- [Firebase — Manage Session Cookies](https://firebase.google.com/docs/auth/admin/manage-cookies): referência para troca de comprovação de identidade, proteção CSRF e revogação em sessões web. O identificador opaco proposto aqui tem estado próprio no backend; não é simplesmente o cookie JWT nativo do Firebase.
- [AWS — Transactional Outbox Pattern](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html): commit local e publicação separados, com necessidade de tratar mensagens duplicadas nos consumidores.
- [Firebase — Manage User Sessions](https://firebase.google.com/docs/auth/admin/manage-sessions): revogação precisa de verificação/estado adequado; verificar assinatura de token não equivale a verificar sua revogação.
- [Firebase — How Security Rules work](https://firebase.google.com/docs/rules/rules-behavior): revisar regras coincidentes ao restringir documentos sensíveis.
- [Google Cloud — Secret Manager best practices](https://docs.cloud.google.com/secret-manager/docs/best-practices): privilégio mínimo e versões explícitas dos segredos.
- [BullMQ — Going to production](https://docs.bullmq.io/guide/going-to-production): Redis de fila com `noeviction` e requisitos de operação; a persistência da fila não substitui o procedimento de recuperação descrito neste projeto.

Registro obrigatório de acompanhamento: [matriz de achados, evidências e encerramento](#15-matriz-de-achados-e-evidências). Esta revisão documental não fecha achados, não implanta a nova autorização e não altera o token operacional.

## 15. Matriz de achados e evidências

Registro de 30/10/2026 — America/Fortaleza. **Nenhum achado está formalmente encerrado apenas por sua inclusão neste documento.**

### 15.1. Origem e alcance

A auditoria externa fornecida pelo usuário examinou o commit `69bc581` por leitura de arquivos e seis reproduções isoladas de lógica. Ela não executou a suíte original nem verificou produção. A revisão local posterior conferiu código modificado, alguns artefatos implantados e testes selecionados. Os dois conjuntos de evidências têm alcances diferentes; um não invalida automaticamente o outro.

Os IDs C1–C16 seguem a ordem dos achados no relatório anexado. E1–E9 registram pendências adicionais da revisão e da definição de produto. As prioridades abaixo são de execução deste plano, não uma classificação CVSS atribuída pela auditoria externa.

- **P0:** bloquear acesso indevido, exposição de credenciais ou execução privilegiada; corrigir antes do piloto de dados.
- **P1:** corrigir integridade, efeitos externos, recuperação e comportamento essencial antes da entrega afetada.
- **P2:** corrigir funcionalidade/observabilidade com fase e aceite explícitos; não abandonar no backlog.

Responsável técnico por todos os achados: engenharia da plataforma SaaS. A fase 0 deve atribuir um responsável nominal a cada entrega. Dependências de provedor, distribuição mobile e infraestrutura são registradas separadamente.

### 15.2. Revisão e implantação observadas

Na revisão anterior desta conversa, em 30/10/2026:

- HEAD local e `main` remoto: `69bc5818e4149ae91b1d028d5634f2af84785972`.
- Diretório de trabalho: 98 entradas versionadas alteradas e 67 entradas não rastreadas. Esta contagem é histórica, anterior à edição dos documentos desta revisão.
- As correções posteriores examinadas estavam sem commit de correção identificável. **Não preencher esse campo com o HEAD antigo.**
- As imagens verificadas não tinham `org.opencontainers.image.revision`. Houve comparação de arquivos selecionados; isso não prova equivalência de todos os arquivos/configurações da implantação.

#### Identificação dos artefatos examinados

| Componente | Identificação observada | Limite da verificação |
| --- | --- | --- |
| API | imagem `sha256:d9fa8bec4fc788aade149d8277f2474ee2d80a44c04628f6a0b6de1b52a3447c` | `dist/middlewares/auth.js` e `dist/routes/providers.routes.js` iguais aos locais |
| Proxy | imagem `sha256:ce00e7cfc5f2f75edfdb7d96859a8b1ff88590493d1fa864cecbebcb31e826ea` | `index.js` e `lib/client-access.js` iguais aos locais |
| Worker | imagem `sha256:5371a5711558d996ab80a4da89efeae3756843bf1a96683979be7d910d4695ca` | `worker.js` igual ao local |
| Builder | imagem `sha256:f28c2bf9ce46c249aa05b704273477c89e261d5c20e63f985de01a47c60b878b` | `services/apk-builder/index.js` e `scripts/build/generate-apk.py` iguais aos locais |
| Landing | imagem `sha256:502b490da61023424561f4f4df08043cb2747ade43876fc61324cfb2e073fdf1` | `script.js` igual ao local |
| Speed test | imagem `sha256:eab4b54699eb3a65e6b297cf34746a21f45094348e4b296011bb7f558a0a8544` | `server.js` igual ao local |
| Firestore Rules | ruleset `47258516-c7d0-4049-b8d7-c34cff758795` | SHA-256 `226860389a96a65a99c848b428173cc67efe0c7476b0ff736a6764faabfe914e`, igual ao arquivo local |
| Storage Rules | ruleset `9158f9a8-0f7c-4073-8aec-2ba82f23315f` | SHA-256 `31dcb74737449dc82b08c3f611082d7bc0dcaac6652a2bc0dce08e64b145fc4d`, igual ao arquivo local; release do bucket `app-ajust-provedor.firebasestorage.app` |
| `handleFunctionRequest` | build `4df7a02a-31a1-4c90-9f5c-38a854958500`, região `southamerica-east1`, Node.js 22 | Arquivos compilados de `requestRouter`, `permissions`, `clientPage`, `backups` e `sgp` iguais aos locais no pacote de origem da implantação |

O pacote da Function consultado foi `handleFunctionRequest/function-source.zip`, geração `1793313738531838`, no bucket de fontes `gcf-v2-sources-2735150999-southamerica-east1`. As quatro Functions listadas estavam `ACTIVE`. Estado ativo não comprova correção funcional.

O APK distribuído e a adoção de versões pelos dispositivos **não foram revalidados nessa revisão**. Não estender a igualdade de código Flutter local a todos os aplicativos instalados.

#### Testes executados naquela revisão

| Execução | Resultado observado | O que não comprova |
| --- | --- | --- |
| `npm test --prefix api-service` | 37 testes aprovados | Todos os fluxos reais, todos os papéis em todos os transportes ou SGP real |
| `./node_modules/.bin/vitest run` dentro de `functions` | 67 testes aprovados | Comportamento completo de triggers sob queda real ou restauração |
| `node --test` nos cinco arquivos listados abaixo | 8 testes aprovados | Integração completa de Redis, login real ou aplicativos distribuídos |
| `npm run test:rules` | **Bloqueado antes dos testes:** CLI instalado exigia Java 21; host usava Java 17 | Não contar como aprovado nem como falha de uma regra específica |

Os cinco arquivos foram `proxy-sgp/lib/client-access.test.js`, `proxy-sgp/lib/subscriber-profile.test.js`, `proxy-sgp/lib/internal-secret.test.js`, `proxy-sgp/lib/sync-page.test.js` e `speed_test_server/server.test.js`.

Existe log anterior com seis testes de regras aprovados; ele é evidência histórica, não substitui a execução na revisão de release. Os resultados acima são uma transcrição do que foi observado; os logs completos sanitizados e o manifesto de execução ainda precisam ser arquivados junto ao commit de entrega.

### 15.3. Matriz C1–C16

Em todas as linhas, **commit de correção: não identificado para as alterações locais posteriores ao HEAD auditado**. Cada encerramento deve atualizar esse campo com o commit efetivo e a referência do manifesto de implantação.

| ID / prioridade | Achado e situação do código | Teste / evidência disponível | Situação de implantação | Fase e condição de encerramento |
| --- | --- | --- | --- | --- |
| C1 / P0 | Papel de assinante confundido com administrador: causa específica corrigida por papel explícito. Revogação uniforme ainda pendente | Testes negativos na API, helpers de identidade e permissões; regras não reexecutadas nesta revisão | API, proxy, regras e permissões da Function comparados | F1: todos os papéis/tenants negados ou permitidos em HTTP, fila, Firestore e Storage; incluir tokens antigos e novo limite SaaS/provedor |
| C2 / P0 | Login por CPF: senha exigida no backend e enviada pelo Flutter atual | Helper testa senha vazia/incorreta e identidade; falta jornada completa por versão de cliente | Código do proxy conferido; adoção do APK não comprovada | F1: CPF sem senha falha; senha correta funciona; contrato encerrado e SGP indisponível tratados; refresh de perfil não reabre login inseguro |
| C3 / P0 | Colisão de tabelas: cache atual usa `(provider_id, client_id)` | Inspeção de schema/queries; falta teste específico dos IDs conflitantes e reconciliação histórica | Código de proxy/worker conferido | F1/F5: `isp-a` e `ispa` com mesmo ID externo ficam isolados; dados antigos sem mistura e exceções documentadas |
| C4 / P0 | Entrada aninhada de credenciais no documento público: **aberto** | POST de provedores filtra só parte dos campos; testes de regras não protegem Admin SDK | Rota problemática igual à implantada | F1: schemas de entrada/saída, consulta anônima sem segredo sintético, credenciais somente SaaS/backend; cobrir backups e auditoria |
| C5 / P0 | Destinos SGP/SSRF: **aberto**; políticas de proxy e API diferentes | Inspeção confirma lacunas; testes existentes da API não cobrem toda a conexão/redirect | Proxy problemático conferido; não houve exploração de rede | F1: IPv4/IPv6/DNS/redirect controlados; conexão usa endereço validado; tenant não pode alterar URL ou injetar destino/token |
| C6 / P0 | Fallback global: bloqueado para tenant identificado; modo sem tenant ainda existe | Teste da API para integração incompleta; falta equivalente de todos os caminhos do proxy | Código de resolução no proxy conferido | F1: segredo global fictício nunca sai em requisição de tenant sem segredo; modo global inventariado e isolado/desativado |
| C7 / P1 | Conclusão de sync: job/status corrigem anúncio prematuro; dual-write e publicação parcial continuam | Inspeção do polling/worker; testes de offset/repetição; faltam falhas entre bancos e publicação por geração | Worker/handler conferidos; painel distribuído não revalidado por hash nesta revisão | F1: sucesso só terminal e erro explícito. F5: geração publicada após reconciliação, retomada sem mistura; testar 250 e 5.000 clientes |
| C8 / P1 | Lock sem lease e qualquer erro tratado como duplicidade: **aberto** | Inspeção de `requestRouter`; falta teste de interrupção antes/depois do efeito | Arquivo compilado da Function conferido | F1: posse expira, erro transitório não some; reexecução segura ou estado desconhecido com reconciliação |
| C9 / P1 | Falha de faturas como vazio: exceção agora retorna erro; validação de payload precisa de cobertura | Inspeção de `Promise.all` e resposta de erro; falta teste dedicado uma/duas falhas | Proxy conferido | F1: vazio legítimo, erro total, resposta parcial/ inválida distinguíveis; não cachear erro como sucesso |
| C10 / P1 | Notificações de outro provedor: fallback removido no Flutter atual | Inspeção de queries restritas ao próprio tenant; falta E2E com dois provedores | Código-fonte apenas nesta revisão; APK/adoção pendentes | F1/F6: app de A nunca consulta B; próprios resultados funcionam; versão legada tem destino documentado |
| C11 / P1 | Restore de configuração por merge: **aberto** | Inspeção de `restoreProviderConfig` | Arquivo compilado da Function conferido | F1/F4: restaurar exatamente campos personalizáveis; excluir campos novos; backup de personalização não contém nem altera token, URL SGP, identidade Android ou acesso |
| C12 / P1 | Colisão de applicationId/artefatos: **aberto** | Normalização conflita e saída depende do nome comercial | Builder e script conferidos | F1: impedir novo conflito/sobrescrita. F7: applicationId persistido e único, artefato por tenant/versão/build; preservar pacotes e assinaturas existentes |
| C13 / P1 | Símbolos de ofuscação temporários: **aberto** | Script gera símbolos temporários e copia somente APK/AAB | Script conferido; sem prova de retenção externa | F1: preservar antes da limpeza. F7: recuperar símbolos por build e simbolizar falha de teste; acesso privado |
| C14 / P2 | Formulário comercial confirma envio inexistente: **aberto** | Handler espera e mostra sucesso sem envio | `script.js` da landing conferido | F1: remover falso sucesso; usar contato explícito ou destino persistente. Testar recebimento controlado, falha e preservação dos campos |
| C15 / P2 | Contagem sem filtro: código agora usa o mesmo filtro e cursor | Inspeção de `clientPage`; falta teste funcional dedicado | Arquivo compilado da Function conferido | F1: 100 registros, busca de 2 retorna total 2; navegação e cursor coerentes, inclusive busca sem resultado |
| C16 / P1 | Speed test: limites globais implementados, sessão individual ainda ausente | Teste isolado de limites/capabilities aprovado; sem homologação conjunta | `server.js` conferido | F1/F7: autorização de sessão, duração/concorrência/abuso; medir impacto nas APIs e declarar teto sem apresentá-lo como capacidade do plano do cliente |

### 15.4. Pendências adicionais

| ID / prioridade | Pendência | Entrega e verificação |
| --- | --- | --- |
| E1 / P1 | Indicadores, tendências, badges e `/diagnostic/analyze` com resultados predeterminados | F0 inventaria consumidores; F1 usa N/D/indisponível ou medida real. Rota 501 deve comunicar indisponibilidade e ter destino no inventário |
| E2 / P0 | Builder com credencial administrativa e acesso a assinatura no mesmo ambiente de execução | F1 remove acesso indevido; F7 separa executor/assinatura/publicação; teste de negação a banco, segredos e administração |
| E3 / P0 | Nova política de produto: token e geração exclusivos do SaaS; legado ainda concede acesso a secrets/backups ao provedor | F1 aplica matriz em UI, API, callables, RPC, regras, IAM e caminhos alternativos; testar também restauração de backups antigos contendo segredo |
| E4 / P1 | Permissões/sessões divergentes entre API, Functions e SDKs diretos | F1 controla revogação do legado; F3 valida cada etapa antes de mover autoridade; nenhum sucesso de suspensão enquanto acesso residual não estiver bloqueado |
| E5 / P1 | Falta de vínculo commit → testes → artefatos implantados | F0 registra baseline e manifestos; CI fixa ferramentas, Java/Node e imagens; revisão do código sem publicar segredos |
| E6 / P1 | Backup não equivale a PITR/recuperação integral; `archive_mode=off` na inspeção | F2 implanta WAL externo e ensaia baixo volume; F8 recuperação integral. RPO de 5 min ainda não comprovado |
| E7 / P1 | Perda total de Redis e retorno do banco no tempo | F2/F8 testam agenda futura, cancelamentos, reconstrução, quarentena de efeitos externos, revogações posteriores ao ponto restaurado e reabertura controlada |
| E8 / P0 | Token SGP anteriormente público ainda não rotacionado no upstream | Depende do administrador do SGP fornecer substituto; equipe SaaS cadastra/valida. Preservar valor privado operacional e nunca considerar remoção da cópia pública como rotação |
| E9 / P1 | Caminhos públicos e identidade além da fachada principal | F0 mapeia `/api`, `/sgp`, callables, Firestore/Storage e `admin_app`; F1 cobre autorização sem depender de um único gateway. Auditoria de anexos inclui escopo por assinante/ticket, não apenas por tenant |

### 15.5. Evidências operacionais e lacunas

- Backup mais recente verificado pelo status na revisão: **30/10/2026 às 03:04:05 de Fortaleza**, equivalente a `2026-10-30T06:04:05.981Z`. O status consulta o manifesto local de conclusão; não é uma nova restauração integral.
- Log anterior de restauração PostgreSQL: 492 registros de cache carregados. O procedimento também verifica integridade do RDB e arquivos. Isso não comprova recuperação completa de identidades, arquivos, acessos e efeitos externos.
- PostgreSQL observado: `archive_mode=off`, `archive_timeout=0`, `wal_level=replica`. Não há evidência de PITR operacional no estado auditado.
- Redis de fila observado: `appendonly=yes`, `appendfsync=everysec`, `maxmemory-policy=noeviction`. O teste existente verifica reconexão/retry; não comprova recuperação após perda total do armazenamento.
- O worker registra o lembrete diário às 09h de Fortaleza na inicialização. Isso não reconstrói automaticamente todos os jobs e agendamentos futuros perdidos; falta fonte durável completa.
- Memória observada em uma amostra: aproximadamente 4,2 GiB disponíveis e 2,4 GiB de swap em uso. É uma amostra de servidor compartilhado, não reserva disponível para novos serviços.
- [Carga sintética](operations/capacity-report.json): proteção sob sobrecarga produz 503; não certificar 100 mil usuários simultâneos nem esconder rejeições no cálculo de capacidade.
- [Medição de login](operations/login-followup-2026-10-30.json): amostras antes/depois com contas temporárias, sem distribuição suficiente para SLO. Não substituir percentis por uma amostra favorável.

### 15.5.1. Lote 1 F0/F1 — baseline e inventário (31/10/2026)

- **Baseline:** `aeef740` preserva as alterações anteriores ao lote (sobre `69bc581`); `608af5f` registra o manifesto observado de implantação/host. Nenhum dos dois é commit de correção dos achados, e nenhum prova produção homologada. O campo “commit de correção” das matrizes 15.3/15.4 continua **não identificado**.
- **Inventário:** [rearchitecture-f0-f1-inventory-2026-10-31.md](operations/rearchitecture-f0-f1-inventory-2026-10-31.md) mapeia, por arquivo/rota, escritores, consumidores, efeitos e autorização atual de C4, C11, E3 e E9 em HTTP `/api`, `/sgp`, RPC, callables, Firestore/Storage, UI web, `unified`, `admin_app` (consumidor estático de `POST /admin/providers`, incluindo `details.apiToken/systemUrl`), `uploadProviderLogo`, builder e backups; autorizações e efeitos observados no código separados das lacunas de distribuição/IAM. Distingue dados atuais (código do baseline) de históricos (hashes de 30/10, log antigo de regras).
- **Situação por achado após o lote:**

| ID | Código | Testado | Implantado | Distribuído | Situação |
| --- | --- | --- | --- | --- | --- |
| C4 | inventariado; aberto | não | não | não | aberto; entrada/saída aninhada no POST/GET de provedores; auditoria já redige recursivamente por nomes de chave, mas exige cobertura e schema |
| C11 | inventariado; aberto | não | não | não | aberto; restore por merge e backup misto acessível ao provedor |
| E3 | inventariado; aberto | não | não | não | aberto; provedor ainda lê/grava `secrets`, `backups`, aciona RPC de integração/SGP |
| E9 | parcialmente inventariado | não | não | não | aberto; `admin_app` mapeado estaticamente, mas versões em campo, mobile e escopo de anexos pendentes |
| E8 | — | — | — | — | aberto (externo): rotação do token SGP pelo administrador do SGP |

- **Ambiente:** Java 17 incompatível com o CLI de regras (exige Java 21); é necessário ambiente isolado Java 21. Nenhum teste de regras novo.
- **Resultado deste contrato:** inventário documental conferido pelo executor `executor-codex-task-17baa3af4fe4-f0-baseline`; `git diff --check` aprovado (exit 0, uma rodada). Não equivale aos testes históricos da seção 15.2 nem aos testes de aceitação de C4/C11/E3/E9. Fontes adicionais verificáveis: `Caddyfile` (prefixos independentes), `unified/lib/core/providers/configuration_provider.dart` sob `app-flutter` (Firestore/cache), `diagnostic_report_service.dart` (URL compartilhável e tentativa de atualizar histórico) e `admin_app` (serialização sem ID e status 201 incompatível); detalhes e backlog no inventário. Sem implantação/distribuição; revisão independente ainda cabe ao controlador.
- **Ordem de implantação e rollback** (planejada, sem implantação neste lote): API/schemas → painel separado → Functions → regras por último; rollback **sem** reverter regras/Functions restritivas ao baseline (que reabriria `secrets`/backups ao provedor, contra a seção 10): bloqueio temporário ou correção para frente, e retorno apenas de API/painel a artefatos identificados e validados; os artefatos de regras/Functions de retorno não constam do manifesto `608af5f` e permanecem pendentes de identificação. Preservar token privado, personalização, backup misto privado e compatibilidade (inventário, seção 7).
- **Não encerrados:** G0/F0 (dados, IAM, mobile e custo pendentes) e nenhum achado C1–C16/E1–E9 foi fechado neste lote; achados abrangentes só parcialmente cobertos (por exemplo C5, C6, C12, C13, E2, E4–E7) permanecem abertos.

### 15.6. Regra de encerramento e passagem de fase

Nenhuma falha crítica/alta, ou item P0 deste planejamento, será encerrada sem **revisão do código, teste correspondente, resultado e situação da implantação**. Um achado refutado exige reprodução controlada e justificativa verificável. “Não consegui reproduzir” sem ambiente/condições suficientes é inconclusivo.

Cada ficha de encerramento terá:

1. ID, escopo afetado, severidade revisada e responsável.
2. Reprodução anterior ou justificativa de refutação, usando dados sintéticos.
3. Commit corretivo, versão dos contratos/regras e diferenças remanescentes.
4. Comando, ambiente, ferramentas, data, saída sanitizada e resultado dos testes; testes ignorados/bloqueados aparecem explicitamente.
5. Manifesto de imagens/Functions/regras/APK, hashes e situação: somente código, testado, implantado ou distribuído.
6. Verificação pós-implantação e cobertura dos clientes antigos ainda suportados.
7. Risco residual, dependência externa e critério de reabertura.

P0 local não resolvido bloqueia corte de dados e novo piloto público. Uma dependência externa como E8 continua aberta; qualquer avanço deve ter mitigação registrada, responsável, revisão do risco e limites de operação explícitos, nunca um encerramento fictício. P1 bloqueia a entrega que depende de sua correção. P2 tem prazo por fase e também precisa de aceite.

Esta seção registra o estado conhecido; as checklists da seção 9 registram o trabalho a executar. Atualizar as duas seções a cada entrega. Não marcar “resolvido” por existir uma tarefa futura para o achado.
