# Layout 14 - Cyberpunk-Neon Fusion Style Guide

## Conceito Visual
**Cyberpunk-Neon Fusion** - Uma fusão entre a estética cyberpunk futurista e elementos modernos de glassmorphism, criando uma interface high-tech com neon vibrante e camadas translúcidas.

## Paleta de Cores

### Cores Primárias (Neon Cyberpunk)
- **Neon Cyan**: `#00FFFF` - Acentos principais, botões primários
- **Neon Magenta**: `#FF00FF` - Destaques secundários, notificações
- **Neon Yellow**: `#FFFF00` - Alertas, ênfase em dados críticos
- **Neon Green**: `#00FF00` - Status positivo, confirmações

### Cores de Fundo (Dark Mode)
- **Deep Space Black**: `#0A0A0F` - Fundo principal
- **Void Black**: `#050508` - Fundo secundário
- **Dark Purple**: `#1A0A2E` - Fundo de cards e seções

### Cores de Vidro (Glassmorphism)
- **Glass Cyan**: `#00FFFF1A` (10% opacidade)
- **Glass Magenta**: `#FF00FF1A` (10% opacidade)
- **Glass Surface**: `#FFFFFF08` (5% opacidade)

### Cores de Texto
- **Text Primary**: `#FFFFFF` - Texto principal
- **Text Secondary**: `#B0B0C0` - Texto secundário
- **Text Neon**: `#00FFFF` - Texto em destaque

## Tipografia

### Fontes
- **Principal**: "JetBrains Mono" (monospace tech)
- **Alternativa**: "Roboto Mono" ou "Courier New"
- **Títulos**: 24-32px, Bold, Neon Cyan
- **Subtítulos**: 18-20px, Semi-bold, Text Primary
- **Corpo**: 14-16px, Regular, Text Secondary
- **Dados**: 16-24px, Bold, Neon Yellow

## Elementos Visuais

### Efeitos Especiais
1. **Neon Glow**: `box-shadow: 0 0 20px #00FFFF, 0 0 40px #00FFFF40`
2. **Glass Blur**: `backdrop-filter: blur(12px)`
3. **Scan Lines**: Linhas horizontais finas com opacidade 5%
4. **Grid Background**: Grade sutil com linhas neon
5. **Holographic Effect**: Gradientes animados em camadas

### Bordas
- **Neon Border**: `1px solid #00FFFF` com glow
- **Dashed Tech**: `border: 1px dashed #FF00FF`
- **Rounded**: 8-12px (moderado)

### Sombras
- **Neon Shadow**: `0 4px 20px #00FFFF40`
- **Deep Shadow**: `0 8px 32px #00000080`

## Componentes UI

### Botões
```dart
// Primary Button
Neon Cyan background + Glow + Text White
Hover: Aumenta brilho, escala 1.02

// Secondary Button
Glass background + Neon Cyan border
Hover: Preenchimento neon com 20% opacidade

// Danger Button
Neon Magenta background + Glow
```

### Cards
- **Background**: Glass com blur
- **Border**: Neon Cyan (1px) com glow sutil
- **Shadow**: Neon Shadow
- **Hover**: Aumenta brilho, adiciona escala 1.01

### Inputs
- **Background**: Glass escuro
- **Border**: Neon Cyan (1px) em foco
- **Placeholder**: Text Secondary
- **Focus**: Glow neon + escala 1.01

### Navigation
- **Active**: Neon Cyan com glow
- **Hover**: Texto branco + underline neon
- **Background**: Glass com blur

## Layout & Responsividade

### Breakpoints
- **Mobile**: < 600px (1 coluna, cards empilhados)
- **Tablet**: 600-900px (2 colunas, cards flexíveis)
- **Desktop**: > 900px (3 colunas, layout completo)

### Spacing
- **Micro**: 4px
- **Small**: 8px
- **Medium**: 16px
- **Large**: 24px
- **Extra Large**: 32px

## Animações & Micro-interações

### Transições
- **Duration**: 200-300ms
- **Easing**: `ease-out` ou `cubic-bezier(0.4, 0, 0.2, 1)`
- **Hover**: Escala + brilho + cor

### Loading States
- **Spinner**: Neon Cyan com trail
- **Skeleton**: Glass shimmer com neon

### Feedback
- **Success**: Neon Green flash
- **Error**: Neon Magenta pulse
- **Warning**: Neon Yellow blink

## Acessibilidade

### Contraste
- **WCAG AAA**: Texto em fundo escuro > 7:1
- **Neon em preto**: 12:1 (excelente)
- **Branco em preto**: 21:1 (máximo)

### Focus Indicators
- **Outline**: Neon Cyan 2px
- **Glow**: Sombra neon visível
- **Scale**: Aumento 10% no foco

### Touch Targets
- **Mínimo**: 44x44px
- **Botões**: 48x48px mínimo
- **Links**: Área de toque ampliada

### Screen Reader
- **Labels**: Descritivos claros
- **Roles**: Semântica ARIA correta
- **States**: Status visuais anunciados

## Especificações Técnicas

### Flutter Implementation
```dart
// Cores principais
static const Color neonCyan = Color(0xFF00FFFF);
static const Color neonMagenta = Color(0xFFFF00FF);
static const Color neonYellow = Color(0xFFFFFF00);
static const Color neonGreen = Color(0xFF00FF00);

// Fundos
static const Color deepSpace = Color(0xFF0A0A0F);
static const Color voidBlack = Color(0xFF050508);
static const Color darkPurple = Color(0xFF1A0A2E);

// Glass
static const Color glassCyan = Color(0x1A00FFFF);
static const Color glassMagenta = Color(0x1AFF00FF);
static const Color glassSurface = Color(0x0DFFFFFF);

// Texto
static const Color textPrimary = Color(0xFFFFFFFF);
static const Color textSecondary = Color(0xFFB0B0C0);
static const Color textNeon = Color(0xFF00FFFF);
```

### Efeitos Visuais
```dart
// Neon Glow BoxShadow
BoxShadow(
  color: neonCyan.withOpacity(0.6),
  blurRadius: 20,
  spreadRadius: 2,
)

// Glass Effect
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
  child: Container(
    decoration: BoxDecoration(
      color: glassSurface,
      border: Border.all(color: neonCyan, width: 1),
    ),
  ),
)
```

## Inspirações 2025

### Referências
1. **Cyberpunk 2077 UI**: Neon vibrante, dark mode, high-tech
2. **Blade Runner 2049**: Holographic elements, rain effects
3. **Neon Genesis**: Glowing lines, grid backgrounds
4. **Modern Fintech**: Glass cards, data visualization
5. **Sci-Fi Dashboards**: Real-time metrics, scan lines

### Tendências Aplicadas
- ✅ Cyberpunk aesthetics (neon, dark mode)
- ✅ Glassmorphism (transparência, blur)
- ✅ Retro-futurism (tech vintage)
- ✅ Micro-interactions (hover effects)
- ✅ Accessibility (contraste, foco)
- ✅ Responsividade (mobile-first)

## Checklist de Implementação

- [ ] Paleta de cores aplicada
- [ ] Tipografia configurada
- [ ] Efeitos neon implementados
- [ ] Glassmorphism em cards
- [ ] Animações suaves
- [ ] Acessibilidade verificada
- [ ] Responsividade testada
- [ ] Documentação completa

---
**Status**: 🚀 Pronto para implementação
**Data**: 20/12/2025
**Versão**: 1.0