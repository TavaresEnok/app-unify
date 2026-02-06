# Manual de Infraestrutura do Sistema

**Última Atualização:** 30/01/2026
**Responsável:** Equipe de Desenvolvimento

Este documento serve como o guia definitivo para a infraestrutura do servidor, detalhando a organização, portas, segredos e tecnologias utilizadas (Docker, Portainer, Firebase).

---

## 1. Visão Geral da Arquitetura

O servidor foi reorganizado para suportar múltiplos projetos simultâneos sem conflitos. Adotamos a filosofia de **"Containers Isolados"**, onde cada projeto vive em seu próprio ambiente Docker, gerenciado visualmente pelo Portainer.

### Estrutura de Diretórios
Toda a organização reside em `/home/app/projects/`:
```text
/home/app/projects/
├── _shared/                # Scripts e Certificados compartilhados
├── portainer/              # Gestão Visual do Docker
├── painel_provedores/      # [EM BREVE] O Sistema Atual (Painel + App)
├── hub_ajust/              # O Sistema Migrado (Python/Vue)
└── [outros_projetos]/      # Futuros sistemas
```

---

## 2. Mapa de Portas (Port Matrix)

Para evitar erros de "Address already in use", cada sistema tem sua faixa de portas exclusiva.

| Sistema | Serviço | Porta Externa | Porta Interna | Descrição |
| :--- | :--- | :--- | :--- | :--- |
| **Infra** | **Portainer** | `9000` | 9000 | **Painel de Controle Docker** |
| **Infra** | SSH | `22` | 22 | Acesso Terminal |
| | | | | |
| **Painel Atual** | Frontend Admin | `5174` | - | Painel Vite (React) |
| **Painel Atual** | SGP Proxy | `3002` | 3002 | Integração API SGP |
| **Painel Atual** | Backend API | `3000` | 3000 | Servidor Node (se ativo) |
| | | | | |
| **Hub_Ajust** | Backend API | `8010` | 8000 | FastAPI Python |
| **Hub_Ajust** | Frontend | `8011` | 80 | Vue.js |
| **Hub_Ajust** | Banco (PG) | `5434` | 5432 | PostgreSQL Isolado |
| **Hub_Ajust** | Redis | `6381` | 6379 | Cache Isolado |

> **Regra:** Novos projetos devem usar a faixa `8030+`, `8050+`, etc.

---

## 3. Credenciais e Acesso (Segurança)

### 🔐 Acesso ao Servidor
*   **Usuário Linux:** `app` (ou `backupp` para legados)
*   **Caminho Projetos:** `/home/app/projects/`

### 🐳 Acesso Portainer (Gestão Docker)
*   **URL:** `http://SEU_IP:9000`
*   **Usuário Inicial:** `admin` (Definido no primeiro acesso)
*   **Função:** Permite reiniciar containers, ver logs e subir novos projetos sem usar terminal.

### 🔥 Credenciais Firebase (Painel Provedores)
As chaves de API não ficam salvas neste documento por segurança. Elas residem no código fonte:
*   **Arquivo de Configuração:** `src/firebase/config.ts` (Frontend) e `functions/src/index.ts` (Backend).
*   **Projeto:** `painel-provedores-projeto`
*   **Serviços Usados:**
    *   *Auth:* Gestão de usuários e logins.
    *   *Firestore:* Banco de dados NoSQL em tempo real.
    *   *Storage:* Armazenamento de Logos e APKs.
    *   *Functions:* Lógica de Backend Serverless (Uploads, Geração APK).

### ☁️ Hub_Ajust (Sistema Migrado)
*   **Arquivo de Senhas:** Consulte o arquivo `.env` dentro da pasta `/home/app/projects/hub_ajust/`.
*   **Banco de Dados:** Usuário `postgres`, Senha definida no `.env`.

---

## 4. Tecnologias Explicadas

### Docker 🐋Containerização
O Docker permite que o Python do "Hub_Ajust" não interfira no Node.js do "Painel Provedores".
*   **Comando Útil:** `docker ps` (Lista o que está rodando).
*   **Reiniciar serviço:** `docker restart [nome_container]`.

### Portainer 🚢 Gestão Visual
Interface gráfica para o Docker.
*   **Stacks:** É onde definimos os projetos (equivalente ao docker-compose).
*   **Containers:** Onde vemos os processos rodando.
*   **Logs:** Clique num ícone de "papel" ao lado do container para ver erros.

### Firebase 🔥 Backend Serverless
Substitui a necessidade de um servidor de banco de dados tradicional para o Painel Provedores.
*   Não precisa de manutenção de servidor (backup de banco, etc), o Google gerencia.
*   **Emuladores:** Usamos as portas `4000`, `8080`, `9099` para testes locais.

---

## 5. Procedimentos Comuns

### Como subir um novo projeto?
1.  Crie a pasta em `/home/app/projects/novo_projeto`.
2.  Coloque o `docker-compose.yml` lá.
3.  Acesse o Portainer (`:9000`) > Stacks > Add stack.
4.  Selecione "Web editor" e cole o conteúdo do `docker-compose.yml` (ou aponte para o Git).
5.  Clique em "Deploy the stack".

### Como fazer backup?
1.  **Código:** Tudo está no Git.
2.  **Dados (Hub_Ajust):** O volume do banco está em `/home/app/projects/hub_ajust/data`. Copie essa pasta.
3.  **Dados (Painel Provedores):** Estão na nuvem do Google (Firebase), backup é automático/exportável pelo console do Firebase.

---
**Documento Gerado por:** Assistente de Infraestrutura (Antigravity)
