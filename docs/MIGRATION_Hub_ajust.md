# Hub_Ajust - Documentação Completa de Migração (AI-to-AI Handoff)

**Data de Criação:** 2026-01-30  
**Servidor Atual:** 168.194.13.17  
**Usuário do Sistema:** backupp  
**Senha do Sistema:** `asdSD@91582685`

---

## 📊 INFORMAÇÕES GERAIS DO SISTEMA

### Estrutura de Diretórios
```
/home/backupp/Hub_Ajust/
├── backend/              # Backend FastAPI Python
├── frontend/             # Frontend Vue.js + Vite
├── .env                  # Variáveis de ambiente
├── docker-compose.yml    # Orquestração de containers
├── migrate_backup.sh     # Script de backup (executável)
└── backups/              # Diretório para backups
```

### Tecnologias Utilizadas
- **Backend:** FastAPI (Python 3.11+), SQLAlchemy, Alembic, Celery
- **Frontend:** Vue.js 3, Vite, Pinia, Axios, Lucide Icons
- **Banco de Dados:** PostgreSQL 16
- **Cache/Queue:** Redis 7
- **Orquestração:** Docker + Docker Compose
- **Web Server (Frontend):** Nginx (dentro do container)

---

## 🔐 CREDENCIAIS E SENHAS

### Sistema Operacional
- **IP Servidor Atual:** `168.194.13.17`
- **Usuário:** `backupp`
- **Senha:** `asdSD@91582685`
- **Privilégios:** Usuário com acesso sudo

### Banco de Dados PostgreSQL
- **Host (interno):** `postgres` (dentro da rede Docker `ajust_net`)
- **Host (externo):** `localhost` ou `168.194.13.17`
- **Porta (interna):** `5432`
- **Porta (externa):** `5434`
- **Usuário:** `postgres`
- **Senha:** `change_this_password_in_prod`
- **Database:** `ajust_hub`
- **Connection String:** `postgresql://postgres:change_this_password_in_prod@postgres:5432/ajust_hub`

### Redis
- **Host (interno):** `redis`
- **Host (externo):** `localhost`
- **Porta (interna):** `6379`
- **Porta (externa):** `6381`
- **Senha:** Nenhuma (sem autenticação)

### API Backend (FastAPI)
- **Secret Key:** `super_secret_key_change_me_12345`
- **Algorithm:** `HS256`
- **Token Expiration:** `60` minutos (1 hora)

### API Externa SGP
- **URL:** `https://sgp.tonynet.com.br`
- **Token:** (precisa ser configurado no .env como `SGP_API_TOKEN`)
- **App Name:** `TONYNET`

### Usuários da Aplicação (no banco)
**Nota:** Os usuários são criados via seed ou registro. Senhas precisam ser hasheadas.
- Email padrão: `admin@tonynet.com.br`
- Role: `super_admin`, `noc_engineer`, ou `isp_owner`

---

## 🌐 PORTAS UTILIZADAS

| Serviço | Porta Externa | Porta Interna | Protocolo |
|---------|---------------|---------------|-----------|
| Backend API | 8010 | 8000 | HTTP |
| Frontend | 8011 | 5173 (dev) / 80 (prod) | HTTP |
| PostgreSQL | 5434 | 5432 | TCP |
| Redis | 6381 | 6379 | TCP |

**Importante:** As portas externas podem ser alteradas no `.env` se houver conflito no novo servidor.

---

## 🐳 CONTAINERS DOCKER

### 1. Backend (ajust_backend)
- **Container Name:** `ajust_backend`
- **Image:** Build local de `./backend/Dockerfile`
- **Porta:** `8010:8000`
- **Comando:** `uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`
- **Volume:** `./backend:/app`
- **Rede:** `ajust_net`
- **Depende de:** `postgres`, `redis`

### 2. Worker Celery (ajust_worker)
- **Container Name:** `ajust_worker`
- **Image:** Build local de `./backend/Dockerfile`
- **Comando:** `celery -A app.core.celery_app worker -B --loglevel=info`
- **Volume:** `./backend:/app`
- **Rede:** `ajust_net`
- **Depende de:** `redis`, `postgres`, `backend`

### 3. Frontend (ajust_frontend)
- **Container Name:** `ajust_frontend`
- **Image:** Build local de `./frontend/Dockerfile`
- **Porta:** `8011:5173`
- **Volume:** 
  - `./frontend:/app`
  - `/app/node_modules` (volume anônimo)
- **Rede:** `ajust_net`
- **Depende de:** `backend`

### 4. PostgreSQL (ajust_postgres)
- **Container Name:** `ajust_postgres`
- **Image:** `postgres:16-alpine`
- **Porta:** `5434:5432`
- **Volume:** `ajust_postgres_data:/var/lib/postgresql/data`
- **Variáveis:**
  - `POSTGRES_USER=postgres`
  - `POSTGRES_PASSWORD=change_this_password_in_prod`
  - `POSTGRES_DB=ajust_hub`
- **Rede:** `ajust_net`

### 5. Redis (ajust_redis)
- **Container Name:** `ajust_redis`
- **Image:** `redis:7-alpine`
- **Porta:** `6381:6379`
- **Volume:** `ajust_redis_data:/data`
- **Rede:** `ajust_net`

---

## 📁 VOLUMES DOCKER

### Volumes Nomeados (Persistentes)
1. **ajust_postgres_data**
   - Tipo: Volume Docker
   - Conteúdo: Dados do PostgreSQL
   - Localização: `/var/lib/docker/volumes/ajust_postgres_data/_data`

2. **ajust_redis_data**
   - Tipo: Volume Docker
   - Conteúdo: Dados do Redis
   - Localização: `/var/lib/docker/volumes/ajust_redis_data/_data`

### Volumes Bind Mounts (Desenvolvimento)
- `./backend:/app` → Código do backend
- `./frontend:/app` → Código do frontend

---

## 🌐 REDE DOCKER

- **Nome:** `ajust_net`
- **Driver:** `bridge`
- **Subnet:** Auto-atribuído pelo Docker
- **Comunicação Interna:** Containers usam nomes de serviço como hostname (`postgres`, `redis`, `backend`)

---

## 🗃️ ESTRUTURA DO BANCO DE DADOS

### Principais Tabelas

#### 1. `users`
```sql
id               UUID PRIMARY KEY
email            VARCHAR UNIQUE NOT NULL
hashed_password  VARCHAR NOT NULL
role             VARCHAR (super_admin, noc_engineer, isp_owner)
is_active        BOOLEAN DEFAULT TRUE
tenant_id        UUID (FK → tenants.id)
created_at       TIMESTAMP
```

#### 2. `tenants`
```sql
id          UUID PRIMARY KEY
name        VARCHAR NOT NULL
is_active   BOOLEAN DEFAULT TRUE
created_at  TIMESTAMP
```

#### 3. `service_orders` (Ordens de Serviço)
```sql
id                UUID PRIMARY KEY
protocol          VARCHAR UNIQUE
tenant_id         UUID (FK → tenants.id)
client_name       VARCHAR
technician_name   VARCHAR
service_type      VARCHAR
status            VARCHAR (open, in_progress, closed, canceled)
sgp_status        VARCHAR (from SGP API)
description       TEXT
created_at        TIMESTAMP
closed_at         TIMESTAMP
deadline          TIMESTAMP
```

#### 4. Outras Tabelas
- `occurrences` - Ocorrências/atualizações das OS
- `projects` - Projetos do NOC (legado)
- `timeline_events` - Eventos de timeline (legado)
- `alembic_version` - Controle de migrações

---

## 📋 ARQUIVO .ENV COMPLETO

```env
# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=change_this_password_in_prod
POSTGRES_DB=ajust_hub
POSTGRES_PORT=5432
POSTGRES_EXTERNAL_PORT=5434
POSTGRES_SERVER=postgres

# Backend API
APP_PORT=8010
SECRET_KEY=super_secret_key_change_me_12345
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# Redis
REDIS_HOST=redis
REDIS_PORT=6381

# API SGP (Configurar conforme necessário)
SGP_API_URL=https://sgp.tonynet.com.br
SGP_API_TOKEN=YOUR_TOKEN_HERE
SGP_APP_NAME=TONYNET

# Frontend (adicionar se necessário)
VITE_API_URL=http://168.194.13.17:8010/api/v1

# CORS (adicionar se necessário)
ALLOWED_ORIGINS=http://168.194.13.17:8011,http://localhost:8011
```

---

## 🚀 ENDPOINTS DA API

### Base URL
- **Desenvolvimento:** `http://168.194.13.17:8010`
- **Docs (Swagger):** `http://168.194.13.17:8010/docs`
- **ReDoc:** `http://168.194.13.17:8010/redoc`

### Principais Endpoints

#### Autenticação
- `POST /api/v1/login/access-token` - Login
- `POST /api/v1/auth/register` - Registro (se disponível)

#### NOC Dashboard
- `GET /api/v1/noc/dashboard-stats` - Estatísticas gerais

#### Técnicos (5 endpoints)
- `GET /api/v1/noc/technicians/ranking`
- `GET /api/v1/noc/technicians/performance`
- `GET /api/v1/noc/technicians/overdue-stats`
- `GET /api/v1/noc/technicians/{tech_name}/details`
- `GET /api/v1/noc/technicians/timeline`

#### Provedores (3 endpoints)
- `GET /api/v1/noc/providers/ranking`
- `GET /api/v1/noc/providers/frequency`
- `GET /api/v1/noc/providers/service-matrix`

#### Tipos de Serviço (3 endpoints)
- `GET /api/v1/noc/service-types/ranking`
- `GET /api/v1/noc/service-types/duration`
- `GET /api/v1/noc/service-types/tech-matrix`

#### SLA (5 endpoints)
- `GET /api/v1/noc/sla/score`
- `GET /api/v1/noc/sla/delay-distribution`
- `GET /api/v1/noc/sla/critical-overdue`
- `GET /api/v1/noc/sla/trends`

---

## 🎨 ROTAS DO FRONTEND

### Base URL
- **Acesso:** `http://168.194.13.17:8011`

### Rotas Públicas
- `/login` - Página de login

### Rotas Protegidas (requer autenticação)
- `/portal` - Layout principal
- `/portal/noc/dashboard` - Dashboard geral NOC
- `/portal/noc/technicians` - Dashboard de técnicos
- `/portal/noc/providers` - Dashboard de provedores
- `/portal/noc/service-types` - Dashboard de tipos de serviço
- `/portal/noc/sla` - Dashboard de SLA
- `/portal/admin/dashboard` - Dashboard admin (super_admin)
- `/portal/admin/orders` - Ordens globais (super_admin)
- `/portal/admin/tenants` - Gestão de clientes (super_admin)

---

## 🔧 COMANDOS PARA MIGRAÇÃO

### FASE 1: BACKUP NO SERVIDOR ATUAL

```bash
# 1. Conectar ao servidor atual
ssh backupp@168.194.13.17
# Senha: asdSD@91582685

# 2. Navegar até o projeto
cd /home/backupp/Hub_Ajust

# 3. Executar script de backup
./migrate_backup.sh

# Este script irá criar:
# - backups/ajust_db_TIMESTAMP.sql (backup do PostgreSQL)
# - /home/backupp/Hub_Ajust_migration_TIMESTAMP.tar.gz (projeto compactado)
# - backups/migration_summary_TIMESTAMP.txt (resumo)
```

### FASE 2: TRANSFERIR PARA NOVO SERVIDOR

```bash
# Substitua NEW_SERVER_IP e NEW_SERVER_USER pelos valores corretos

# Transferir tarball do projeto
scp /home/backupp/Hub_Ajust_migration_*.tar.gz NEW_SERVER_USER@NEW_SERVER_IP:/opt/

# Transferir backup do banco
scp /home/backupp/Hub_Ajust/backups/ajust_db_*.sql NEW_SERVER_USER@NEW_SERVER_IP:/opt/

# Opcional: Transferir via rsync (mais eficiente)
rsync -avz --progress /home/backupp/Hub_Ajust_migration_*.tar.gz NEW_SERVER_USER@NEW_SERVER_IP:/opt/
rsync -avz --progress /home/backupp/Hub_Ajust/backups/ NEW_SERVER_USER@NEW_SERVER_IP:/opt/backups/
```

### FASE 3: PREPARAÇÃO NO NOVO SERVIDOR

```bash
# 1. Conectar ao novo servidor
ssh NEW_SERVER_USER@NEW_SERVER_IP

# 2. Extrair o projeto
cd /opt
tar -xzf Hub_Ajust_migration_*.tar.gz
cd Hub_Ajust

# 3. Ajustar permissões
sudo chown -R $USER:$USER /opt/Hub_Ajust
chmod +x migrate_backup.sh

# 4. IMPORTANTE: Editar .env com novo IP
nano .env

# Alterar no .env:
# VITE_API_URL=http://NEW_SERVER_IP:8010/api/v1
# ALLOWED_ORIGINS=http://NEW_SERVER_IP:8011,http://localhost:8011
```

### FASE 4A: DEPLOY VIA DOCKER COMPOSE (Método Direto)

```bash
# No novo servidor, dentro de /opt/Hub_Ajust

# 1. Subir containers
docker-compose up -d

# 2. Aguardar containers iniciarem (30-60 segundos)
sleep 60

# 3. Verificar status
docker-compose ps

# Todos devem estar "Up"
```

### FASE 4B: DEPLOY VIA PORTAINER (Método Recomendado)

```bash
# 1. Acesse Portainer
# URL: http://NEW_SERVER_IP:9000

# 2. Login no Portainer com suas credenciais

# 3. Criar Stack:
#    - Stacks → + Add stack
#    - Name: hub-ajust
#    - Build method: Upload

# 4. Upload do docker-compose.yml
#    Arquivo: /opt/Hub_Ajust/docker-compose.yml

# 5. Adicionar Environment Variables:
#    Copiar todas as variáveis do .env:
#    
#    POSTGRES_USER=postgres
#    POSTGRES_PASSWORD=change_this_password_in_prod
#    POSTGRES_DB=ajust_hub
#    POSTGRES_PORT=5432
#    POSTGRES_EXTERNAL_PORT=5434
#    POSTGRES_SERVER=postgres
#    APP_PORT=8010
#    SECRET_KEY=super_secret_key_change_me_12345
#    ALGORITHM=HS256
#    ACCESS_TOKEN_EXPIRE_MINUTES=60
#    REDIS_HOST=redis
#    REDIS_PORT=6381
#    VITE_API_URL=http://NEW_SERVER_IP:8010/api/v1
#    ALLOWED_ORIGINS=http://NEW_SERVER_IP:8011,http://localhost:8011

# 6. Deploy the stack

# 7. Aguardar containers subirem (verificar em Containers)
```

### FASE 5: RESTAURAR BANCO DE DADOS

```bash
# No novo servidor

# 1. Aguardar PostgreSQL estar pronto
docker logs ajust_postgres 2>&1 | grep "database system is ready to accept connections"

# 2. Restaurar backup
cat /opt/ajust_db_*.sql | docker exec -i ajust_postgres psql -U postgres -d ajust_hub

# 3. Verificar dados
docker exec -it ajust_postgres psql -U postgres -d ajust_hub -c "SELECT COUNT(*) FROM service_orders;"

# 4. Executar migrações Alembic (se necessário)
docker exec ajust_backend alembic upgrade head
```

### FASE 6: CONFIGURAR FIREWALL

```bash
# No novo servidor

# 1. Abrir portas necessárias
sudo ufw allow 8010/tcp comment "Hub_Ajust Backend API"
sudo ufw allow 8011/tcp comment "Hub_Ajust Frontend"

# Se usar Nginx reverse proxy:
sudo ufw allow 80/tcp comment "HTTP"
sudo ufw allow 443/tcp comment "HTTPS"

# 2. Recarregar firewall
sudo ufw reload

# 3. Verificar regras
sudo ufw status numbered
```

### FASE 7: VERIFICAÇÃO E TESTES

```bash
# 1. Verificar containers rodando
docker ps | grep ajust
# Deve mostrar: ajust_backend, ajust_frontend, ajust_postgres, ajust_redis, ajust_worker

# 2. Verificar logs
docker-compose logs -f --tail=50

# 3. Testar API Backend
curl http://NEW_SERVER_IP:8010/health
# Deve retornar: {"status":"healthy"}

# 4. Testar documentação Swagger
curl http://NEW_SERVER_IP:8010/docs
# Deve retornar HTML da página Swagger

# 5. Testar endpoint de login
curl -X POST "http://NEW_SERVER_IP:8010/api/v1/login/access-token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin@tonynet.com.br&password=YOUR_PASSWORD"

# 6. Testar Frontend
# Abra no navegador: http://NEW_SERVER_IP:8011
# - Deve carregar a página de login
# - Faça login
# - Verifique os 4 dashboards especializados no menu lateral
```

---

## 🎯 AJUSTES ESPECÍFICOS PARA PORTAINER

### Configuração de Volumes no Portainer

Quando criar a stack no Portainer, certifique-se de que os volumes sejam criados:

1. **Acesse:** Volumes → + Add volume
2. **Criar:**
   - Nome: `ajust_postgres_data`
   - Driver: `local`
   
3. **Repetir para:**
   - Nome: `ajust_ redis_data`
   - Driver: `local`

### Configuração de Rede no Portainer

A rede `ajust_net` será criada automaticamente pelo stack, mas você pode pré-criar:

1. **Acesse:** Networks → + Add network
2. **Configurar:**
   - Nome: `ajust_net`
   - Driver: `bridge`
   - IPV4 Subnet: `172.28.0.0/16` (opcional)

---

## 🔍 TROUBLESHOOTING DETALHADO

### Problema: Backend não conecta ao banco

```bash
# 1. Verificar se o PostgreSQL está rodando
docker ps | grep ajust_postgres

# 2. Verificar logs do PostgreSQL
docker logs ajust_postgres

# 3. Testar conexão manual
docker exec -it ajust_postgres psql -U postgres -d ajust_hub

# 4. Verificar variável de ambiente no backend
docker exec ajust_backend env | grep DATABASE

# 5. Se necessário, recriar backend
docker-compose restart backend
```

### Problema: Frontend não carrega

```bash
# 1. Verificar se container está rodando
docker ps | grep ajust_frontend

# 2. Verificar logs
docker logs ajust_frontend

# 3. Verificar se build foi feito
docker exec ajust_frontend ls -la /app/dist

# 4. Rebuild se necessário
docker-compose build --no-cache frontend
docker-compose up -d frontend
```

### Problema: CORS Error no navegador

```bash
# 1. Editar .env e adicionar:
ALLOWED_ORIGINS=http://NEW_SERVER_IP:8011,http://localhost:8011

# 2. Reiniciar backend
docker-compose restart backend

# 3. Verificar configuração
docker exec ajust_backend env | grep ALLOWED_ORIGINS
```

### Problema: Dashboards sem dados

```bash
# 1. Verificar se banco tem dados
docker exec -it ajust_postgres psql -U postgres -d ajust_hub -c "SELECT COUNT(*) FROM service_orders;"

# 2. Se retornar 0, popular dados
docker exec ajust_backend python seed.py

# OU importar da API SGP
docker exec ajust_backend python fetch_service_orders.py
```

---

## 📊 SCRIPTS AUXILIARES

### Script de Verificação Completa

Criar arquivo: `/opt/Hub_Ajust/verify_system.sh`

```bash
#!/bin/bash
echo "=== Hub_Ajust System Verification ==="
echo ""

echo "1. Checking containers..."
docker ps --filter "name=ajust" --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "2. Checking database connection..."
docker exec ajust_postgres psql -U postgres -d ajust_hub -c "SELECT version();"

echo ""
echo "3. Checking service orders count..."
docker exec ajust_postgres psql -U postgres -d ajust_hub -c "SELECT COUNT(*) as total_orders FROM service_orders;"

echo ""
echo "4. Testing backend API..."
curl -s http://localhost:8010/health | jq '.'

echo ""
echo "5. Checking volumes..."
docker volume ls --filter "name=ajust"

echo ""
echo "=== Verification Complete ==="
```

**Tornar executável:**
```bash
chmod +x /opt/Hub_Ajust/verify_system.sh
./verify_system.sh
```

---

## 📝 CHECKLIST FINAL PARA AI

```markdown
☐ 1. Backup realizado no servidor atual
☐ 2. Arquivos transferidos para novo servidor
☐ 3. Projeto extraído em /opt/Hub_Ajust
☐ 4. Arquivo .env editado com novo IP
☐ 5. Portas 8010 e 8011 liberadas no firewall
☐ 6. Stack criado no Portainer OU docker-compose up executado
☐ 7. Todos os 5 containers rodando (backend, frontend, postgres, redis, worker)
☐ 8. Banco de dados restaurado do backup
☐ 9. Migrações Alembic executadas
☐ 10. API acessível em http://NEW_IP:8010/docs
☐ 11. Frontend acessível em http://NEW_IP:8011
☐ 12. Login funcionando
☐ 13. Dashboard geral carregando
☐ 14. 4 dashboards especializados visíveis no menu lateral
☐ 15. Dados visíveis nos dashboards (ou seed executado)
☐ 16. Servidor antigo mantido em standby (30 dias)
```

---

## 🎯 INSTRUÇÕES ESPECÍFICAS PARA OUTRA IA

### Ordem de Execução

1. **Ler este documento completamente** para entender a arquitetura
2. **Executar FASE 1** no servidor atual (168.194.13.17)
3. **Executar FASE 2** para transferir arquivos
4. **Executar FASE 3** para preparar novo servidor
5. **Escolher FASE 4A ou 4B** (Portainer recomendado)
6. **Executar FASE 5, 6, 7** em sequência
7. **Marcar checklist** conforme avança
8. **Reportar problemas** usando seção de Troubleshooting

### Informações Críticas

- **NUNCA deletar servidor antigo** até validação completa (mínimo 30 dias)
- **IPs devem ser atualizados** no .env e em ALLOWED_ORIGINS
- **Senhas devem ser mantidas** iguais ou documentadas se alteradas
- **Portas podem ser alteradas** se houver conflito, atualizar variáveis correspondentes
- **Backup do banco é ESSENCIAL** antes de qualquer operação

---

**Documento criado em:** 2026-01-30  
**Versão do Sistema:** Hub_Ajust v1.0  
**Última atualização:** Implementação de dashboards especializados completa  
**Próxima revisão:** Após migração bem-sucedida
