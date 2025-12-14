# 🎨 HANDOFF: Criar Layout 04 para App Unificado

## 📋 RESUMO
Crie o **Layout 04** para o app Flutter de autoatendimento de provedores de internet.

**Layouts existentes:** 02 (Clássico), 03 (Minimalista), 05 (Neumorphism), 06 (Premium Dark), 07 (Clean Light)

**Sua missão:** Criar algo visualmente impressionante e único. **Total liberdade criativa!**

---

## 🏗️ ESTRUTURA

```
/home/app/painel-provedores-projeto/app-flutter/unified/
├── lib/
│   ├── layout_selector.dart      # ⭐ REGISTRAR AQUI
│   └── layouts/
│       └── layout_04/            # [CRIAR ESTA PASTA]
│           ├── dashboard_page.dart
│           ├── login_page.dart
│           ├── financeiro_page.dart
│           ├── diagnostico_page.dart
│           ├── wifi_page.dart
│           ├── suporte_page.dart
│           ├── consumo_page.dart
│           ├── meu_ip_page.dart
│           ├── faq_page.dart
│           ├── contrato_page.dart
│           └── theme.dart
```

---

## 🔧 INTEGRAÇÃO

### 1. Registrar no `layout_selector.dart`
```dart
// Imports
import 'layouts/layout_04/dashboard_page.dart' as l04;
import 'layouts/layout_04/login_page.dart' as l04_login;
// ... demais imports

// Adicionar cases nos switchs
case 'layout_04':
  return l04.DashboardPage(onNavigate: onNavigate);
```

### 2. Adicionar no Admin Web
Arquivo: `admin-painel/src/pages/provider-settings/AppearanceSettings.tsx`
```tsx
<SelectItem value="layout_04">Layout 04 - Seu Nome</SelectItem>
```

---

## 🔌 SERVICES (usar os existentes em `lib/core/`)

```dart
// Autenticação
final auth = context.read<AuthService>();
await auth.performLogin(cpf, config);
final usuario = auth.usuario;

// Configuração do Provedor
final config = context.read<ConfigurationProvider>();
final logo = config.providerConfig?.config.logoUrl;

// Navegação (no Dashboard)
onNavigate('invoices');  // faturas
onNavigate('wifi');      // wifi
onNavigate('support');   // suporte
```

---

## 🚀 GIT - COMO FAZER COMMIT E PUSH

### Chave SSH
O repositório usa autenticação SSH. A chave privada está em:
```
~/.ssh/github_unify
```

### Comandos Git

```bash
# 1. Navegar para o diretório do projeto
cd /home/app/painel-provedores-projeto/app-flutter/unified

# 2. Ver status das alterações
git status

# 3. Adicionar todos os arquivos
git add -A

# 4. Criar commit
git commit -m "feat: Add Layout 04 - Nome do Estilo"

# 5. Push para GitHub (usando a chave SSH)
GIT_SSH_COMMAND="ssh -i ~/.ssh/github_unify -o StrictHostKeyChecking=no" git push origin main
```

### ⚠️ IMPORTANTE
- A branch é `main` (não `master`)
- Sempre use `GIT_SSH_COMMAND` para autenticar
- Não há senha, a chave SSH faz a autenticação automaticamente

### Exemplo Completo (copie e cole)
```bash
cd /home/app/painel-provedores-projeto/app-flutter/unified && \
git add -A && \
git commit -m "feat: Add Layout 04 - Nome do Estilo" && \
GIT_SSH_COMMAND="ssh -i ~/.ssh/github_unify -o StrictHostKeyChecking=no" git push origin main
```

---

## ✅ CHECKLIST

- [ ] Criar pasta `lib/layouts/layout_04/`
- [ ] Implementar todas as páginas (dashboard, login, financeiro, etc.)
- [ ] Registrar no `layout_selector.dart`
- [ ] Adicionar opção no `AppearanceSettings.tsx`
- [ ] Testar build: `flutter build apk --debug`
- [ ] Fazer commit e push

---

**Use sua criatividade! Boa sorte! 🎨**
