# Painel Provedores

Sistema completo para provedores de internet com app mobile white-label e painel administrativo.

## 🏗️ Arquitetura

```
├── admin-painel/       # Painel web React (administração)
├── app-flutter/
│   ├── admin_app/      # App wrapper WebView para admin
│   └── unified/        # App mobile white-label
├── functions/          # Firebase Cloud Functions
├── api-service/        # API Node.js auxiliar
├── proxy-sgp/          # Proxy para integração SGP
└── docs/               # Documentação
```

## 🚀 Começando

### Pré-requisitos

- Node.js 18+
- Flutter 3.4+
- Firebase CLI

### Configuração

1. **Clone o repositório**
```bash
git clone <repo-url>
cd painel-provedores-projeto
```

2. **Configure o Firebase**
```bash
firebase login
firebase use --add
```

3. **Instale dependências**
```bash
# Admin Painel
cd admin-painel && npm install

# Functions
cd ../functions && npm install

# App Flutter
cd ../app-flutter/unified && flutter pub get
```

### Executando

**Admin Painel (desenvolvimento)**
```bash
cd admin-painel
npm run dev
```

**App Flutter**
```bash
cd app-flutter/unified
flutter run
```

**Functions (emulador local)**
```bash
firebase emulators:start
```

## 📱 App Flutter

O app é white-label com múltiplos layouts visuais:
- Layout 02, 03, 05, 06 (default), 07

O layout é selecionado dinamicamente via configuração no Firestore (`layoutType`).

## 🔧 Configuração do Provedor

1. Acesse o painel admin
2. Configure: nome, logo, cores, layout
3. O app carrega automaticamente a configuração

## 📚 Documentação

- [Arquitetura](docs/ARCHITECTURE.md)
- [API SGP](docs/sgp-api.md)
- [Análise de Código](docs/CODE_ANALYSIS.md)

## 🛠️ Scripts Úteis

| Script | Descrição |
|--------|-----------|
| `01_backup.sh` | Backup do sistema |
| `02_transferir.sh` | Transferir arquivos |
| `iniciar.sh` | Iniciar serviços |
