# Primeiro lote F0/F1 — inspeção de 31/10/2026 UTC

Coordenação: gerente Paseo `e4e7beb1-03af-4207-a183-664af14df188`. Implementação/revisão: ainda sem executor admitido; job `17baa3af4fe4` preservado na fila. E8: administrador externo do SGP emite/revoga; equipe SaaS cadastra/valida.

## Base preservada e implantação

- `aeef740`: snapshot das correções locais preexistentes, sem atribuir-lhes homologação nova. Origem em `69bc581`, 98 arquivos versionados alterados e 68 entradas não rastreadas (166 entradas de status). `.claude/`, arquivos ignorados e credenciais não foram copiados.
- `608af5f`: manifesto de containers observados, sem revision OCI. Comparação de IDs confirma imagens API/proxy/worker/builder históricas; não comprova igualdade integral de código/configuração. Functions/regras remotas/APKs ainda não revalidados.
- `2373f8c`: nove arquivos locais do backup `20261030T060338Z-2223424` coincidem com hashes do manifesto. Não prova restauração integral nem disponibilidade remota atual.
- Clone de desenvolvimento: `/home/app/srv_projetos/workspace/painel_provedores`, branch `orchestration/17baa3af4fe4`. Origem preservada, sem reset, limpeza ou commits de implementação novos.
- Host observado: 3,3 GiB disponíveis, swap em uso, disco 87%; uma admissão ficou limitada por pressão de memória. Nenhum serviço alheio alterado. Não há orçamento para nova pilha presumido.

## Inventário mínimo conferido no código

| Caminho/consumidor | Autoridade/escritor atual | Controle e lacuna confirmados | Destino |
| --- | --- | --- | --- |
| Caddy `/api/*` → API, GET/POST provedores (`api-service/src/routes/providers.routes.ts`) | Firestore via Admin SDK | Admin/tenant; objeto genérico e remoção incompleta de campos aninhados; auditoria recebe payload | C4: schema de entrada/saída e auditoria |
| Painel `shared/firebase/providerSettingsService.ts` | Firestore direto | Listener de `secrets/sgp` e batch de integração; personalização acoplada | E3: separar fluxo SaaS privado da personalização |
| RPC `UPDATE_PROVIDER_CONFIG`/`UPDATE_PROVIDER_DETAILS` (`functions/src/handlers/providers.ts`) | Admin SDK escreve público e secrets | `requireProviderAccess` também permite trocar integração; nome/destino fora de limite explícito | C4/E3: allowlists e autorização SaaS |
| RPC backup/list/restore/delete (`functions/src/handlers/backups.ts`) | Firestore backups + doc público + secrets | Backup copia segredo; restore merge regrava segredo e conserva campos ausentes | C11/E3: backup sanitizado e restore exato |
| Firestore `provedores` e legado `providers` | SDKs diretos e backend | Secrets/backups e wildcards concedem `canManageProvider`; regras coincidentes mantêm acesso | C1/E3/E9: fechar sobreposições |
| Storage assets/anexos/relatórios | SDKs diretos | Assets públicos; anexos autorizados por tenant, sem comprovação de escopo por ticket/assinante | E9: teste por recurso, em lote próprio |
| Caddy `/sgp/*` → proxy, RPC `SGP_API_PROXY` | SGP externo + cache | Há resolução privada e rotas de uso/sync; não concluir SSRF/fallback pela inspeção parcial | C5/C6: adapter e política de saída em próximo lote |
| `/apk-builder/generate-apk`, `/jobs/:jobId` | Builder e arquivos locais | HTTP exige claim SaaS; não consulta revogação atual; worker/credenciais/assinatura ainda precisam análise | E2/E3/E4, C12/C13 |
| Callable `generateApk` | Processo Python no ambiente Function | Checa claim SaaS; deriva package normalizando ID e executa subprocesso | E2/E3/C12/C13, não homologado |
| Flutter unified | Firestore/Storage/RPC/HTTP conforme domínio | Código não comprova versões instaladas | Inventariar pacotes, assinatura e adoção antes de corte |
| Flutter admin_app `core/services/api_service.dart` | Consumidor HTTP `/admin/providers` | Cliente existe no código; uso real e roteamento suportado não demonstrados | E9: manter inventário aberto |
| Backup operacional scripts/ops | PostgreSQL, Redis, Firestore/Auth, arquivos privados | Manifesto concluído e integridade local; restauração integral/PITR não demonstrados | E6/E7: fases próprias |

## Testes e limites

Java 21 foi extraído em diretório isolado de ferramentas, sem instalar pacote global ou mudar alternativas do host. Uma execução conjunta dos seis testes existentes de Firestore/Storage passou no projeto `demo-painel-rearchitecture`. Ver `rearchitecture-2026-10-31/validation.json` e log sanitizado. O teste de segredo explicitamente permite leitura por providerAdmin: este resultado comprova comportamento legado e **não** fecha E3/G1. Secret scan e `git diff --check` passaram na base copiada. Não foram executadas suítes por funcionalidade nem carga real.

## Sequência de entrega e rollback

1. Implementação delimitada C4/C11/E3 de configuração/backups em worktree e revisão independente; preservar token privado, impedir restauração ou publicação dele. Builds/SSRF/revogação são entregas seguintes, ainda abertas.
2. Testes essenciais agrupados no fim do bloco, inclusive regressões negativas de regras com segredo sintético e personalização funcional sem listener de secrets. O verde do baseline não substitui novos critérios.
3. Antes de deploy: validar backup e recuperação do escopo, inventariar Functions/regras remotas e hashes web, preparar imagens/artefatos anteriores e manifesto de release. Ainda não há pacote de rollback aprovado.
4. Ordem precisa ser compatível entre UI/backend/regras: painel novo sem dependência secrets e backend restrito; fechar SDKs/wildcards no mesmo lote controlado. Não liberar UI que necessite permissões já negadas nem reabrir segredos por compatibilidade.
5. Rollback não pode restaurar regras que reabram segredos. Em falha, restringir mutações afetadas e corrigir para frente; restaurar personalização sem tocar credencial ou identidade Android. Nunca restaurar banco antigo sobre produção para desfazer release comum.

## Backlog e bloqueio

F0 ainda aberto: inventário integral de consumidores/dados, orçamento representativo, IAM/custos, ADRs e rastreabilidade de artefatos remotos/mobile. C1–C16/E1–E9 permanecem abertos conforme critérios individuais. E8 não pode ser encerrado sem substituição e revogação upstream, indisponíveis; segredo operacional não foi removido nem exibido.

O controlador registrou três recusas `policy_changed` em admissão, antes da criação de executor (attempt=0). Esse erro indica divergência de seleção/admissão; não é prova de esgotamento de todas as contas. O gerente não implementa nem contorna tickets. Nenhum recover repetido, executor duplicado, reinício de daemon ou alteração de outro projeto foi realizado. A fila persiste aguardando admissão válida. Estado: baseline documentado/testado no alcance descrito; nenhuma nova correção de produto implementada, implantada ou distribuída.
