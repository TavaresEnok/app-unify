# 🎨 Prompt para Criação de 3 Layouts Únicos - App Flutter ISP

## Contexto do Projeto

Você está trabalhando em um aplicativo Flutter para provedores de internet (ISP). O app permite que clientes vejam faturas, testem velocidade, configurem Wi-Fi, etc. Já existem layouts (02, 03, 05, 06, 07) e você precisa criar **3 NOVOS LAYOUTS COMPLETAMENTE ÚNICOS** (08, 09, 10).

**IMPORTANTE:** NÃO copie os layouts existentes. Pesquise na web por tendências de design mobile 2024/2025, inspirações no Dribbble, Behance, Mobbin, e crie algo INOVADOR.

---

## 📋 Requisitos Técnicos Obrigatórios

### Sistema de Temas Dinâmicos
Todos os layouts DEVEM usar o sistema de cores dinâmico via `ThemeConfig`:
- Cores vêm de `config?.colors.primary`, `config?.colors.secondary`, etc.
- NUNCA hardcode cores - sempre use getters dinâmicos
- O admin panel configura cores, então o layout deve respeitar isso

### Estrutura de Arquivos (para cada layout)
```
lib/layouts/layout_XX/
├── theme.dart           # Tema e decorações
├── login_page.dart      # Página de login
├── dashboard_page.dart  # Dashboard principal
├── pages/
│   └── speed_test_page.dart
└── widgets/
    ├── bottom_nav.dart
    ├── [widget_unico].dart  # Widgets exclusivos do layout
    └── skeleton_dashboard_page.dart
```

### Parâmetros do Dashboard (obrigatórios)
```dart
DashboardPage({
  required String customerName,
  required String planName,
  required String connectionStatus,
  required double billAmount,
  required DateTime billDueDate,
  required double usedGb,
  required double totalGb,
  required double downloadMbps,
  required double uploadMbps,
  required Function(String) onNavigate,
  List<Map<String, dynamic>>? menuItems,
  Future<void> Function()? onRefresh,
})
```

### Rotas de Navegação
```dart
// O onNavigate recebe estas strings:
'invoices'        // Faturas
'speed_test'      // Teste de velocidade
'wifi'            // Configurações Wi-Fi
'support'         // Suporte
'network_diagnostic' // Diagnóstico
'internet_usage'  // Consumo
'my_ip'           // Meu IP
'contract'        // Contrato
'faq'             // FAQ
'trace_route'     // Traceroute
'notifications'   // Notificações
```

---

## 🎯 MISSÃO: Criar 3 Layouts REVOLUCIONÁRIOS

### Antes de começar, PESQUISE:
1. **Dribbble** - Busque por "mobile app dashboard 2024", "fintech app design", "ISP app UI"
2. **Behance** - Procure por "dark mode app", "glassmorphism mobile", "neubrutalism app"
3. **Mobbin** - Analise apps reais de categorias Banking, Utilities, Telecom
4. **Tendências 2024/2025**: Claymorphism, Neubrutalism, Aurora gradients, Mesh gradients, 3D elements, Micro-interactions

---

## 📱 Layout 08 - [ESCOLHA UM ESTILO ÚNICO]

**Sugestões de direção (escolha UMA ou combine):**

### Opção A: Neubrutalism
- Bordas grossas pretas (3-4px)
- Cores sólidas vibrantes (amarelo, rosa, verde limão)
- Sombras offset duras
- Typography bold e contrastante
- Sem gradientes - flat colors only

### Opção B: Claymorphism / 3D Soft
- Elementos parecem feitos de argila/massinha
- Sombras suaves e profundas
- Cores pastel
- Efeito tridimensional nos cards
- Botões "afundados" ao pressionar

### Opção C: Retro Futurism
- Inspirado em sci-fi dos anos 80
- Neon em fundo escuro
- Grades e linhas de perspectiva
- CRT screen effects
- Fontes pixeladas ou monospace

**CRIE UM VISUAL COMPLETAMENTE DIFERENTE DO QUE JÁ EXISTE!**

---

## 📱 Layout 09 - [ESCOLHA OUTRO ESTILO]

**Sugestões de direção:**

### Opção A: Organic / Biomorphic
- Formas orgânicas como bolhas, ondas, curvas
- Blob shapes para cards
- Cores naturais (verde floresta, terracota, azul oceano)
- Animações fluidas como água
- Bordas irregulares

### Opção B: Minimalist Japanese
- Muito espaço em branco (ma)
- Tipografia refinada
- Paleta reduzida (2-3 cores)
- Linhas finas e delicadas
- Assimetria intencional
- Inspirado em wabi-sabi

### Opção C: Cyberpunk / Tech Noir
- Fundo preto com glitch effects
- Cores: magenta, cyan, verde neon
- Terminais de código / HUD style
- Elementos de interface sci-fi
- Fontes tech/futuristas

---

## 📱 Layout 10 - [ESCOLHA OUTRO ESTILO]

**Sugestões de direção:**

### Opção A: Mesh Gradient Paradise
- Gradientes mesh vibrantes no background
- Glass cards sobre gradientes
- Cores que mudam com scroll (parallax color)
- Transições suaves entre seções
- Estilo Apple iOS 17+

### Opção B: Dark Luxury
- Preto verdadeiro (#000000)
- Detalhes em dourado/champagne
- Tipografia serif elegante
- Poucos elementos, muito espaço
- Animações sutis e lentas
- Sensação de app de banco premium

### Opção C: Playful / Friendly
- Ilustrações customizadas
- Mascote/personagem
- Animações divertidas
- Cores alegres mas não infantis
- Micro-interactions em cada toque
- Gamification elements

---

## ⚠️ REGRAS CRÍTICAS

### O que NÃO fazer:
- ❌ Copiar gradientes roxo/cyan dos outros layouts
- ❌ Usar o mesmo estilo de cards em todos os layouts
- ❌ Bottom navigation idêntica
- ❌ Mesma estrutura de dashboard (header + grid de cards)
- ❌ Login page genérica com logo + campo + botão
- ❌ Speed test igual aos outros (gauge circular)

### O que FAZER:
- ✅ Cada layout deve ser IMEDIATAMENTE reconhecível
- ✅ Inventar widgets customizados únicos para cada layout
- ✅ Experimentar com navegação diferente (tabs, drawer, floating menu, side swipe)
- ✅ Reimaginar como mostrar a fatura (não precisa ser um card retangular)
- ✅ Speed test pode ser uma animação diferente (ondas, partículas, foguete, etc)
- ✅ Login pode ter interações diferentes (swipe, carousel, steps)

---

## 🔧 Código de Referência - ThemeConfig

```dart
// Assim deve ser o theme.dart de cada layout
class LayoutXXTheme {
  // Defaults - CORES ÚNICAS para este layout
  static const Color _defaultPrimary = Color(0xFF...);  // COR ÚNICA
  static const Color _defaultSecondary = Color(0xFF...); // COR ÚNICA
  
  // Getters dinâmicos (OBRIGATÓRIO usar config quando disponível)
  static Color primary(ThemeConfig? config) {
    return config?.colors.primary ?? _defaultPrimary;
  }
  
  static Color secondary(ThemeConfig? config) {
    return config?.colors.secondary ?? _defaultSecondary;
  }
  
  // ThemeData
  static ThemeData getTheme(ThemeConfig? config) {
    final primaryColor = primary(config);
    // ... resto do tema
  }
}
```

---

## 📁 Após Criar os Layouts

Atualize estes arquivos:

1. **layout_selector.dart** - Adicionar imports e switch cases
2. **admin-painel/AppearanceSettings.tsx** - Adicionar opções no dropdown

---

## 🎯 Critérios de Sucesso

Cada layout será avaliado por:

1. **Originalidade** (40%) - É realmente diferente dos existentes?
2. **Estética** (30%) - É bonito, moderno, impressiona?
3. **Coerência** (15%) - O estilo é consistente em todas as páginas?
4. **Usabilidade** (15%) - É funcional e fácil de usar?

**Se eu olhar e parecer "mais do mesmo", você falhou.**

---

## 💡 Dica Final

Pense assim: se você mostrar os 3 novos layouts para alguém que nunca viu o app, essa pessoa deveria dizer:

> "Uau, cada um desses parece um app completamente diferente!"

Se parecerem variações do mesmo tema, refaça.

**BOA SORTE! Surpreenda-me com criatividade! 🚀**
