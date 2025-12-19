# 📋 Resumo Completo do Sistema - Painel Provedores

## 🎯 Visão Geral

O **Painel Provedores** é uma **solução completa white-label** para **provedores de internet** que consiste em:

1. **App Flutter Mobile** - Aplicativo para os clientes do provedor
2. **Painel Administrativo Web** - Interface React para gerenciar provedores
3. **Backend Firebase** - Cloud Functions + Firestore + Auth
4. **Proxy SGP** - Integração com sistema ERP SGP

O sistema permite que cada provedor tenha seu **próprio app personalizado** (cores, layout, logo, funcionalidades) gerenciado através do painel web.

---

## 🏗️ Arquitetura do Sistema

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
    │   (React + Vite)    │◄─┼──│    (Node.js + Express)         │
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
    │  │ (02→11)       │  │
    │  └───────────────┘  │
    └─────────────────────┘
```

---

## 📱 1. App Flutter Mobile (`app-flutter/unified/`)

### **Conceito White-Label**
O app é **único** mas se adapta dinamicamente ao provedor. Quando o cliente abre o app:
1. Carrega configurações do Firestore (provedor específico via `providerId`)
2. Aplica tema, cores, layout, funcionalidades baseadas na config
3. Utiliza o `LayoutSelector` para renderizar os componentes corretos

### **Stack Tecnológico**
| Categoria | Pacotes |
|-----------|---------|
| **Firebase** | `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`, `firebase_messaging`, `firebase_analytics`, `firebase_crashlytics` |
| **Estado** | `flutter_riverpod` |
| **UI** | `google_fonts`, `font_awesome_flutter`, `shimmer`, `fl_chart`, `lottie` |
| **Rede/Diagnóstico** | `dart_ping`, `network_info_plus`, `connectivity_plus`, `flutter_internet_speed_test`, `speed_test_dart` |
| **Segurança** | `flutter_secure_storage`, `local_auth` (biometria) |
| **Outros** | `url_launcher`, `image_picker`, `pdf`, `share_plus`, `cached_network_image` |

### **Layouts Disponíveis (9 opções)**
| Layout | Características |
|--------|-----------------|
| `layout_02` | Dashboard, Login |
| `layout_03` | Dashboard, Login |
| `layout_05` | Dashboard, Login, WiFi Page |
| `layout_06` | Dashboard, Login + WiFi/Speed Test (Padrão) |
| `layout_07` | Dashboard, Login |
| `layout_08` | Dashboard, Login, Speed Test (Tema Dark Premium) |
| `layout_09` | Dashboard, Login, Speed Test (Tema Dark) |
| `layout_10` | Dashboard, Login, Speed Test |
| `layout_11` | Dashboard, Login, Speed Test (Completo) |

### **Estrutura de Código**

```
lib/
├── main.dart                    # Entry point + inicialização Firebase
├── layout_selector.dart         # Seletor dinâmico de layouts
├── core/
│   ├── painel_page.dart         # Página principal pós-login
│   ├── models/                  # Modelos de dados (ProviderConfig, Fatura, etc)
│   ├── services/                # Serviços (Financeiro, Suporte, Diagnóstico, etc)
│   ├── providers/               # Riverpod providers
│   ├── pages/                   # Páginas compartilhadas (SharedPage)
│   └── widgets/                 # Widgets reutilizáveis
└── layouts/                     # Implementações específicas de cada layout
```

---

## 🖥️ 2. Admin Painel Web (`admin-painel/`)

### **Stack Tecnológico**
- **Framework**: React + TypeScript + Vite
- **Estilização**: TailwindCSS + shadcn/ui
- **Estado**: React Context
- **Deploy**: Firebase Hosting

### **Níveis de Acesso**

| Role | Acesso | Descrição |
|------|--------|-----------|
| **superAdmin** | Global | Gerencia todos os provedores e usuários |
| **providerAdmin** | Específico | Gerencia as configurações do seu próprio provedor |

### **Módulos de Configuração (Settings)**
- **Aparência**: Cores, logotipos, escolha de layout
- **Funcionalidades**: Ativar/desativar módulos no app
- **Integrações**: Configuração da API SGP
- **Conteúdo**: FAQ, Dicas, Carrossel de banners
- **Comunicação**: Notificações push e mensagens in-app

---

## ⚡ 3. Cloud Functions (`functions/`)

Funções serverless que processam as requisições do painel administrativo de forma segura, validando permissões e atualizando o Firestore.

**Principais triggers:**
- `handleUpdateProviderConfigRequest`: Atualização de temas e layouts
- `handleUpdateProviderDetailsRequest`: Dados cadastrais e integrações
- `handleGetDashboardDataRequest`: Métricas para o SuperAdmin

---

## 🔗 4. Proxy SGP (`proxy-sgp/`)

Servidor intermediário (Node.js/Express) que resolve problemas de CORS e segurança ao conectar o app mobile à API do SGP.

**Funcionalidades:**
- Autenticação de usuários via SGP
- Consulta de faturas e geração de PIX/Boleto
- Abertura de chamados de suporte
- Coleta de dados de consumo e diagnóstico
- Cache local com SQLite para performance

---

## 🔄 5. Fluxo de Dados

1. **Configuração**: Admin define o layout `layout_08` e cores `#000` no painel web.
2. **Sincronização**: Cloud Functions salvam os dados no Firestore.
3. **Carregamento**: App Flutter inicia, lê o `providerId` e baixa a configuração.
4. **Renderização**: `LayoutSelector` identifica `layout_08` e carrega o dashboard correspondente.
5. **Operação**: Cliente solicita 2ª via → App chama Proxy → Proxy chama SGP → SGP retorna PDF → Proxy repassa ao App.

---
*Documento gerado para histórico e consulta rápida do sistema.*
