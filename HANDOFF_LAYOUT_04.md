# 🎨 HANDOFF: Criar Layout 04 (Novo) para App Unificado

## 📋 RESUMO DA TAREFA

Você precisa criar um **novo layout visual (Layout 04)** para um aplicativo Flutter de autoatendimento de clientes de provedores de internet.
Recentemente, o antigo "Layout 04 Aurora" foi removido completamente. Sua missão é criar um **novo e superior Layout 04**.

**Status Atual dos Layouts:**
- **Layout 02:** Clássico (Gradiente Roxo)
- **Layout 03:** Minimalista (Cards Brancos)
- **Layout 05:** Neo Digital (Neumorphism / Soft UI)
- **Layout 06:** Premium Dark (Recomendado/Atual)
- **Layout 07:** Clean Light

**Sua Meta:** Criar o **Layout 04** para preencher a lacuna com algo visualmente impressionante.

**Sugestão de Estilo:**
Você tem **total liberdade criativa**.
O objetivo é criar um layout visualmente impressionante e funcional, diferente dos atuais. Surpreenda!

---

## 🏗️ ARQUITETURA DO SISTEMA

### Estrutura de Pastas
Você deve trabalhar APENAS nestes diretórios:

```
/home/app/painel-provedores-projeto/
├── app-flutter/unified/
│   ├── lib/
│   │   ├── layout_selector.dart  # ⭐ REGISTRAR AQUI
│   │   ├── core/                 # NÃO MEXER (Services/Models)
│   │   │   ├── painel_page.dart  # Wrapper principal
│   │   └── layouts/              # ⭐ SUA PASTA DE TRABALHO
│   │       ├── layout_04/        # [CRIAR ESTA PASTA]
│   │       ├── layout_05/        # Referência (Neumorphism)
│   │       ├── layout_06/        # Referência (Dark)
│   │       └── ...
├── admin-painel/
│   └── src/pages/provider-settings/AppearanceSettings.tsx  # Adicionar opção no Select
```

---

## 📁 ARQUIVOS OBRIGATÓRIOS

Crie a pasta `lib/layouts/layout_04/` contendo:

1.  `dashboard_page.dart` (Home com atalhos e status)
2.  `login_page.dart` (Login com CPF/Senha)
3.  `financeiro_page.dart` (Lista de faturas)
4.  `diagnostico_page.dart` (Status de conexão ONU/Wifi)
5.  `wifi_page.dart` (Gerenciar redes)
6.  `suporte_page.dart` (Canais de atendimento)
7.  `theme.dart` (Cores e Estilos do seu layout)
8.  `widgets/` (Seus widgets customizados)

**IMPORTANTE:**
- **NÃO** use bibliotecas externas novas sem permissão.
- Use `GoogleFonts` se precisar de tipografia diferente.
- Use os **modelos e services existentes** em `lib/core/` (veja abaixo).

---

## 🔧 COMO INTEGRAR (PASSO A PASSO)

### 1. Criar os Arquivos
Baseie-se em `layout_06` para a lógica e mude apenas a UI (o `build` method).

### 2. Registrar no `LayoutSelector` (`lib/layout_selector.dart`)

```dart
// 1. Adicione os imports
import 'layouts/layout_04/dashboard_page.dart' as l04;
import 'layouts/layout_04/login_page.dart' as l04_login;
// ... (outros imports)

// 2. Adicione os cases nos switchs
case 'layout_04':
  return l04.DashboardPage(onNavigate: onNavigate); // Verifique a assinatura!

// 3. Adicione na lista availableLayouts
{
  'id': 'layout_04',
  'name': 'Nome do Seu Layout',
  'description': 'Descrição curta'
},
```

### 3. Habilitar no Admin Web
Edite `admin-painel/src/pages/provider-settings/AppearanceSettings.tsx`:
```tsx
<SelectItem value="layout_04">Layout 04 - Nome (Estilo)</SelectItem>
```

---

## 🔌 INTEGRAÇÃO COM BACKEND (SERVICES)

Você não precisa criar lógica de backend, apenas consumir o que já existe:

**Autenticação (`AuthService`):**
```dart
final auth = context.read<AuthService>();
await auth.performLogin(cpf, config); // Use performLogin, não login()
final usuario = auth.usuario; // Dados do user logado
```

**Configuração (`ConfigurationProvider`):**
```dart
final config = context.read<ConfigurationProvider>();
final logo = config.providerConfig?.config.logoUrl;
final themeColor = config.providerConfig?.config.themeColor;
```

**Dados do Usuário:**
- `usuario.nome`, `usuario.plano`, `usuario.status`
- `usuario.valorFatura` (String formatada), `usuario.vencimentoFatura`

**Navegação:**
- No Dashboard, receba `Function(String) onNavigate`.
- Chame `onNavigate('invoices')` para ir para faturas, etc.
- Use chaves de string: 'dashboard', 'invoices', 'wifi', 'support', 'network_diagnostic'.

---

## 🚀 PROMPT PARA A PRÓXIMA AI

Copie e cole isto no prompt da nova AI:

```markdown
Por favor, atue como um Desenvolvedor Flutter Sênior Especialista em UI/UX.
Sua tarefa é criar o "Layout 04" para o nosso aplicativo.

Contexto:
- O Layout 04 antigo foi apagado. Estamos começando do zero nesta pasta.
- Temos 4 layouts funcionais (02, 03, 05, 06).
- O backend e a lógica core já existem em `lib/core/`.

Instruções:
1. Leia `/home/app/painel-provedores-projeto/HANDOFF_LAYOUT_04.md` para detalhes técnicos.
2. Crie a pasta `lib/layouts/layout_04`.
3. Implemente as telas principais (Login e Dashboard são prioridade) com um design CRIATIVO e MODERNO.
4. Integre com `LayoutSelector` e `AppearanceSettings.tsx`.
5. Garanta que o app compile (`flutter build apk --debug`).
6. Envie o código.

Dica: Use sua criatividade para criar a melhor experiência possível.
```
