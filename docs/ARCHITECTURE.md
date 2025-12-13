# Arquitetura do Sistema

Sistema completo para provedores de internet com app mobile white-label e painel administrativo.

## Visão Geral

```
┌─────────────────────────────────────────────────────────────────┐
│                         FIREBASE                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐ │
│  │   Auth   │  │Firestore │  │ Storage  │  │ Cloud Functions  │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────────┬─────────┘ │
└───────┼─────────────┼─────────────┼─────────────────┼───────────┘
        │             │             │                 │
        └──────┬──────┴──────┬──────┘                 │
               │             │                        │
    ┌──────────▼──────────┐  │  ┌─────────────────────▼──────────┐
    │   Admin Painel Web  │  │  │         Proxy SGP              │
    │   (React + Vite)    │◄─┼──│    (Node.js + Python)          │
    └──────────┬──────────┘  │  └─────────────────────────────────┘
               │             │                        │
               │             │                        ▼
               │             │              ┌─────────────────────┐
               │             │              │     SGP (ERP)       │
               │             │              │  Sistema Externo    │
               │             │              └─────────────────────┘
               │             │
    ┌──────────▼──────────┐  │
    │   App Flutter       │◄─┘
    │   (White-label)     │
    │                     │
    │  ┌───────────────┐  │
    │  │Layout Selector│  │
    │  │ (02,03,05,06,07)│ │
    │  └───────────────┘  │
    └─────────────────────┘
```

## Componentes

### 1. App Flutter (`app-flutter/unified/`)
App mobile white-label com múltiplos layouts visuais.

| Layout | Descrição |
|--------|-----------|
| layout_02 | - |
| layout_03 | - |
| layout_05 | Inclui página WiFi |
| layout_06 | Default |
| layout_07 | - |

**Funcionalidades:**
- Login/Autenticação
- Dashboard com status da conexão
- Financeiro (faturas, pagamentos)
- Suporte (chamados)
- Diagnóstico de rede
- Consumo de dados
- Meu IP
- FAQ
- Contrato

### 2. Admin Painel (`admin-painel/`)
Painel web para administração de provedores.

- **Stack:** React + TypeScript + Vite + TailwindCSS
- **Deploy:** Firebase Hosting (`https://app-ajust-provedor.web.app`)
- **Funções:**
  - Gerenciar provedores
  - Configurar layouts
  - Definir temas/cores
  - Gerenciar clientes

### 3. Cloud Functions (`functions/`)
Backend serverless no Firebase.

### 4. Proxy SGP (`proxy-sgp/`)
Proxy para integração com o sistema SGP (ERP de provedores).

### 5. API Service (`api-service/`)
API Node.js auxiliar.

## Fluxo de Dados

1. **Admin configura provedor** → Salva no Firestore (`layoutType`, tema, cores)
2. **App Flutter inicia** → Carrega configuração do Firestore
3. **LayoutSelector** → Escolhe componentes visuais corretos
4. **Integração SGP** → Via proxy para dados de clientes/faturas
