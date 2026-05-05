# Roadmap de Ascensao SaaS (App do Assinante ISP)

Status: Ativo  
Escopo: App SaaS para provedor (B2B2C), sem virar ERP

---

## Como acompanhar (caixinhas + verde)

Use sempre este padrao:

- Tarefa pendente: `- [ ] Nome da tarefa`
- Tarefa concluida em verde: `- [x] Nome da tarefa <span style="color:green"><strong>CONCLUIDO</strong></span>`

Legenda rapida:

- `[ ]` Nao iniciado
- `[x]` Finalizado
- `CONCLUIDO` em verde = pronto para producao

---

## Meta de produto

Entregar o melhor app de autoatendimento do assinante para ISPs regionais, com foco em:

- reduzir chamados repetitivos
- acelerar pagamento e regularizacao
- aumentar confianca e retencao
- manter integracao com ERP de terceiros (sem competir como ERP)

---

## Fase 1 (0-60 dias) - Blindagem e confianca

Objetivo: remover riscos criticos e estabilizar os fluxos que definem confianca.

### 1.1 Seguranca e autenticacao

- [ ] Substituir login apenas por CPF por login forte (OTP/SMS/WhatsApp ou senha segura)
- [ ] Parar de retornar senha do ERP em qualquer resposta de API
- [ ] Remover logs com payload sensivel (CPF, token, senha, contrato)
- [ ] Revisar armazenamento local de credenciais e expirar sessao de forma segura
- [x] Desativar cleartext traffic nos manifests Android <span style="color:green"><strong>CONCLUIDO</strong></span>
- [ ] Revisar regras Firestore para isolamento estrito por tenant e por usuario
- [ ] Rotacionar segredos e mover tudo para Secret Manager

### 1.2 Fluxos criticos que hoje quebram confianca

- [ ] Corrigir fluxo de tickets ponta a ponta (criar, responder, atualizar status)
- [ ] Corrigir endpoint de Wi-Fi/CPE para nao retornar 501 no fluxo principal
- [ ] Alinhar onboarding com funcionalidades reais (sem prometer o que nao existe)
- [ ] Tornar deep links realmente navegaveis (nao apenas snackbar)

### 1.3 Multi-tenant real

- [ ] Remover hardcodes de `vibe` no app, proxy e API
- [ ] Centralizar resolucao de `providerId` por sessao/config valida
- [ ] Garantir que provider A nunca leia/escreva dados de provider B

### 1.4 Qualidade minima para release confiavel

- [ ] Definir quality gate no CI (lint + build + testes minimos)
- [ ] Criar suite de regressao para Login, Faturas, Suporte e Notificacoes
- [ ] Corrigir links de documentacao quebrados no README

### Gate de saida da Fase 1

- [ ] Zero segredo sensivel exposto
- [ ] Login seguro ativo em producao
- [ ] Tickets funcionando em producao
- [ ] Wi-Fi/CPE funcional no caminho principal
- [ ] Quality gate obrigatorio no pipeline

---

## Fase 2 (60-180 dias) - Produto coeso e escalavel

Objetivo: consolidar UX, reduzir complexidade tecnica e elevar confiabilidade operacional.

### 2.1 UX principal unica (menos dispersao)

- [ ] Consolidar layouts para 1 base principal + variacao controlada por tema
- [ ] Reduzir configuracoes de admin para presets orientados a resultado
- [ ] Transformar suporte em central unica (incidentes + ticket + WhatsApp + telefone)
- [ ] Padronizar mensagens de erro com orientacao clara de proximo passo

### 2.2 Operacao e resiliencia de integracao ERP

- [ ] Introduzir cache de leitura para reduzir dependencia sincrona do ERP
- [ ] Implementar fila/retry/backoff para chamadas instaveis
- [ ] Adicionar rate limit distribuito com storage persistente (ex: Redis)
- [ ] Definir SLO de latencia e disponibilidade para endpoints criticos

### 2.3 Dados e observabilidade

- [ ] Criar eventos de funil (login, pagamento, suporte, abandono)
- [ ] Instrumentar logs estruturados com correlation id
- [ ] Criar dashboard operacional com erros por fluxo e por tenant
- [ ] Criar alertas proativos de incidente para assinantes impactados

### 2.4 Engenharia de produto

- [ ] Fatiar servicos monoliticos grandes (ex: diagnostico)
- [ ] Reduzir duplicacao de codigo entre telas equivalentes
- [ ] Definir contrato de API versionado para app/admin/backend

### Gate de saida da Fase 2

- [ ] UX principal consolidada e previsivel
- [ ] Integracao ERP resiliente em horario de pico
- [ ] Telemetria de funil ativa para decisao de produto
- [ ] Queda relevante de chamados repetitivos

---

## Fase 3 (180-360 dias) - Diferenciacao e lideranca

Objetivo: criar vantagem competitiva dificil de copiar, centrada em experiencia do assinante.

### 3.1 Diferenciais de autoatendimento inteligente

- [ ] Diagnostico guiado por causa provavel (linguagem leiga, sem jargao tecnico)
- [ ] Abertura automatica de chamado com telemetria quando necessario
- [ ] Score de saude da conexao com recomendacoes acionaveis
- [ ] Playbooks automaticos de retencao para risco de churn

### 3.2 Relacao proativa com assinante

- [ ] Centro de incidentes por regiao/status com previsao de normalizacao
- [ ] Notificacao inteligente baseada em evento real de rede/fatura
- [ ] Recuperacao de acesso e regularizacao em ate 1 minuto

### 3.3 Escala SaaS de verdade

- [ ] Pipeline de build/release totalmente automatizado por tenant
- [ ] Esteira padrao de onboard para novos provedores
- [ ] Base de conhecimento e playbook operacional para CS/Suporte

### Gate de saida da Fase 3

- [ ] Produto reconhecido por reduzir suporte reativo
- [ ] Alto uso de autoatendimento com satisfacao
- [ ] Escala de novos provedores com baixo custo operacional

---

## Top 10 entregas em ordem de impacto (master checklist)

- [ ] Login forte + sessao segura
- [ ] Remocao total de senha retornada pelo backend
- [ ] Firestore com isolamento multi-tenant estrito
- [ ] Tickets ponta a ponta funcionando
- [ ] Wi-Fi/CPE funcional no caminho principal
- [ ] Fim dos hardcodes de provedor
- [ ] Layout unico com tema dinamico controlado
- [ ] Cache/fila/retry para ERP em pico
- [ ] Funil de produto com telemetria ativa
- [ ] Diagnostico guiado + abertura automatica de suporte

---

## Quadro semanal de acompanhamento

Semana atual:

- [x] Planejamento semanal fechado <span style="color:green"><strong>CONCLUIDO</strong></span>
- [ ] Execucao tecnica em dia
- [ ] Validacao de QA concluida
- [ ] Deploy seguro aprovado
- [ ] Revisao de metricas concluida

Bloqueios da semana:

- [ ] Sem bloqueios

Se houver bloqueio, registrar aqui com dono e prazo:

- [ ] Bloqueio 1 - dono - prazo - plano de contorno

---

## KPI alvo por fase

Fase 1:

- [ ] 0 incidente de seguranca por credencial exposta
- [ ] 100% dos fluxos criticos com teste de regressao

Fase 2:

- [ ] Reducao consistente de chamados repetitivos
- [ ] Latencia de fluxos criticos dentro do SLO

Fase 3:

- [ ] Aumento de resolucao via autoatendimento
- [ ] Melhora de retencao e satisfacao de assinante

---

## Observacoes de governanca

- Este roadmap deve ser atualizado toda semana.
- Nao adicionar feature nova sem passar no quality gate.
- Prioridade maxima sempre: confianca do assinante + estabilidade de operacao.

---

## Donos por frente (RACI simplificado)

- Produto: priorizacao, escopo, aceite funcional e comunicacao com operacao
- Mobile Flutter: app do assinante, UX, navegacao, fluxos de autoatendimento
- Backend/API: autenticacao, integracoes ERP, tickets, Wi-Fi/CPE, contratos de API
- DevOps/SRE: CI/CD, segredos, observabilidade, SLO, incidentes e release
- QA: regressao de fluxos criticos, criterios de pronto e validacao pre-producao

---

## Cronograma de 12 semanas (inicio imediato)

### Semana 1

- [ ] Kickoff tecnico + freeze de escopo Fase 1 | Dono: Produto
- [ ] Inventario de segredos e plano de rotacao | Dono: DevOps/SRE
- [ ] Mapa de riscos de login/tickets/Wi-Fi | Dono: Backend/API + QA

### Semana 2

- [ ] Remover retorno de senha em respostas de API | Dono: Backend/API
- [ ] Revisar logs e mascarar dados sensiveis | Dono: Backend/API + DevOps/SRE
- [ ] Definir regressao minima automatizada de fluxos criticos | Dono: QA

### Semana 3

- [ ] Implementar login forte (MVP OTP ou senha segura) | Dono: Backend/API + Mobile Flutter
- [ ] Revisar sessao e expirar credenciais de forma segura | Dono: Mobile Flutter
- [ ] Publicar politica de erros de autenticacao no app | Dono: Produto + Mobile Flutter

### Semana 4

- [ ] Corrigir tickets ponta a ponta em ambiente de homologacao | Dono: Backend/API
- [ ] Ajustar telas de suporte para estados reais (loading, erro, sucesso) | Dono: Mobile Flutter
- [ ] Teste de regressao completo em suporte | Dono: QA

### Semana 5

- [ ] Corrigir endpoint principal de Wi-Fi/CPE sem 501 | Dono: Backend/API
- [ ] Validar fluxo de troca/gestao de Wi-Fi no app | Dono: Mobile Flutter
- [ ] Adicionar monitoramento de erros por endpoint | Dono: DevOps/SRE

### Semana 6

- [ ] Remover hardcodes de provedor em app/proxy/api | Dono: Backend/API + Mobile Flutter
- [ ] Padronizar resolucao de providerId por sessao | Dono: Backend/API
- [ ] Teste cruzado de isolamento tenant A/B | Dono: QA

### Semana 7

- [x] Desativar cleartext traffic nos manifests Android | Dono: Mobile Flutter <span style="color:green"><strong>CONCLUIDO</strong></span>
- [ ] Revisar regras Firestore para isolamento estrito | Dono: Backend/API
- [ ] Rodar auditoria de seguranca da Fase 1 | Dono: DevOps/SRE

### Semana 8

- [ ] Ativar quality gate obrigatorio no CI (lint, build, testes) | Dono: DevOps/SRE
- [ ] Corrigir documentacao quebrada de setup e operacao | Dono: Produto + Backend/API
- [ ] Preparar release candidate Fase 1 | Dono: QA + DevOps/SRE

### Semana 9

- [ ] Consolidar UX principal para base unica com tema | Dono: Mobile Flutter
- [ ] Reduzir variacoes de layout nao essenciais | Dono: Produto + Mobile Flutter
- [ ] Padronizar mensagens de erro por jornada | Dono: Produto

### Semana 10

- [ ] Implementar cache de leitura para chamadas ERP | Dono: Backend/API
- [ ] Implementar retry/backoff em chamadas instaveis | Dono: Backend/API
- [ ] Definir SLO de endpoints criticos | Dono: DevOps/SRE

### Semana 11

- [ ] Instrumentar eventos de funil (login, pagamento, suporte) | Dono: Mobile Flutter + Backend/API
- [ ] Adicionar correlation id em logs ponta a ponta | Dono: Backend/API
- [ ] Construir dashboard operacional por tenant | Dono: DevOps/SRE

### Semana 12

- [ ] Revisao executiva Fase 1 e Fase 2 parcial | Dono: Produto
- [ ] Plano de entrada da Fase 3 com metas trimestrais | Dono: Produto + DevOps/SRE
- [ ] Publicar baseline de KPI e comparativo antes/depois | Dono: Produto + QA

---

## Baseline de status inicial (20/04/2026)

### Ja identificado como risco critico

- [x] Login apenas com CPF como risco de seguranca <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] Hardcodes de provedor em pontos do stack <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] Fragilidade em fluxos de ticket e Wi-Fi/CPE <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] Necessidade de quality gate forte no CI <span style="color:green"><strong>CONCLUIDO</strong></span>

### Entregas tecnicas (execucao)

- [ ] Login forte implantado em producao
- [ ] Remocao completa de retorno de senha no backend
- [ ] Isolamento multi-tenant validado por teste automatizado
- [ ] Tickets funcionando em producao
- [ ] Wi-Fi/CPE funcional no fluxo principal
- [ ] Quality gate obrigatorio no pipeline

### Cadencia de status

- [ ] Atualizar este baseline toda segunda-feira ate 10h
- [ ] Registrar owner e prazo de cada bloqueio da semana
- [ ] Publicar resumo quinzenal de KPI e risco residual

---

## Plano tatico imediato (20/04/2026 a 03/05/2026)

### Objetivo da quinzena

- [ ] Eliminar exposicao de senha e log sensivel no backend
- [ ] Congelar contrato minimo do fluxo Login -> Faturas -> Suporte
- [ ] Definir regressao automatizada minima de fluxos criticos

### Sprint A (Dias 1-5)

- [x] Mapear endpoints que retornam credenciais e remover campos sensiveis | Dono: Backend/API <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] Criar mascaramento padrao de logs (CPF, token, contrato) | Dono: Backend/API <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] Publicar checklist de validacao de seguranca no CI | Dono: DevOps/SRE + QA <span style="color:green"><strong>CONCLUIDO</strong></span>

### Sprint B (Dias 6-10)

- [x] Implementar testes de regressao API (login, faturas, tickets) | Dono: QA + Backend/API <span style="color:green"><strong>CONCLUIDO</strong></span>
- [ ] Validar fluxo de suporte ponta a ponta em homologacao | Dono: QA + Mobile Flutter
- [ ] Registrar baseline de latencia dos endpoints criticos | Dono: DevOps/SRE

- [x] Artefato tecnico preparado: `scripts/measure_api_latency.sh` para gerar baseline em homologacao <span style="color:green"><strong>CONCLUIDO</strong></span>

### Entregaveis obrigatorios da quinzena

- [ ] Evidencia de que API nao retorna senha em nenhum endpoint
- [ ] Evidencia de logs saneados em homologacao
- [ ] Relatorio de regressao com taxa minima de sucesso >= 95%

---

## Dependencias criticas e mitigacao

- [ ] Acesso a segredos e variaveis de ambiente de todos os servicos
Mitigacao: criar janela unica com DevOps para inventario e rotacao.

- [ ] Massa de teste de clientes e contratos para validar tickets e faturas
Mitigacao: congelar dataset de homologacao e versionar fixture.

- [ ] Estabilidade do ERP para testes de integracao em horario util
Mitigacao: usar cache e replay de resposta para testes automatizados.

---

## Definicao de pronto (DoD) da Fase 1

- [ ] Backend: sem retorno de senha, logs mascarados, contrato de erro padronizado
- [ ] Mobile: login seguro funcional, sessao segura, fluxo suporte sem falha bloqueante
- [ ] QA: regressao critica automatizada e executada no pipeline
- [ ] DevOps/SRE: quality gate ativo e bloqueando merge com falha critica
- [ ] Produto: onboarding alinhado com funcionalidades reais e textos revisados

---

## Mapa tecnico de execucao por servico (quinzena)

### Sprint A - Seguranca de credenciais e logs

- [x] `proxy-sgp/index.js`: remover campo `senha` de respostas de login/check-cpf e payloads mock <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] `proxy-sgp/index.js`: revisar logs de debug para nao expor CPF, contrato e dados de acesso <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] `proxy-sgp/proxy.php`: remover logs de payload bruto e resposta bruta do SGP <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] `api-service/src/index.ts`: padronizar erro de login sem eco de payload sensivel <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] `functions/src/generate_token.ts`: remover log de token gerado <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] `functions/src/index.ts`: revisar escrita/leitura de `apiToken` e limitar exposicao em respostas <span style="color:green"><strong>CONCLUIDO</strong></span>

### Sprint B - Regressao e confiabilidade

- [x] Criar testes para fluxo admin auth (`/admin/auth/login`) e erro seguro <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] Criar testes para fluxo check-cpf sem retorno de senha <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] Criar teste de sanitizacao de logs (smoke) no pipeline <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] Criar teste de contrato de erro padronizado (401/403/500) <span style="color:green"><strong>CONCLUIDO</strong></span>

### Evidencias obrigatorias por item

- [x] Evidencia 1: diff mostrando remocao de campos sensiveis <span style="color:green"><strong>CONCLUIDO</strong></span>
- [ ] Evidencia 2: log de homologacao sem CPF/token/senha em texto plano
- [x] Evidencia 3: saida de testes com status de sucesso <span style="color:green"><strong>CONCLUIDO</strong></span>
- [ ] Evidencia 4: screenshot/arquivo de pipeline com quality gate ativo

---

## Rotina diaria de execucao (D1 a D10)

### D1-D2

- [x] Levantar rotas e payloads com risco de vazamento <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] Definir padrao unico de mascaramento de logs <span style="color:green"><strong>CONCLUIDO</strong></span>

### D3-D4

- [x] Aplicar correcoes no proxy e api-service <span style="color:green"><strong>CONCLUIDO</strong></span>
- [x] Revisar cloud functions relacionadas a token/claims <span style="color:green"><strong>CONCLUIDO</strong></span>

### D5

- [ ] Revisao tecnica cruzada Backend + DevOps + QA

### D6-D7

- [ ] Implementar suite minima de regressao de seguranca
- [ ] Integrar suite ao pipeline de CI

### D8-D9

- [ ] Rodar regressao completa em homologacao
- [ ] Corrigir gaps bloqueantes encontrados

### D10

- [ ] Emitir relatorio quinzenal com evidencias e risco residual
- [ ] Atualizar baseline e KPI da Fase 1