# Layout 07 – Pôr‑do‑Sol Tropical (Final)

Implementação fiel ao mockup com todas as correções técnicas aplicadas.

## 📱 Características do Mockup

| Elemento | Implementação |
|----------|---------------|
| Cards Status/Fatura | **Lado a lado** |
| Botões de Serviço | **Gradientes coloridos** (Internet, Suporte, TV, Config) |
| Badge do Plano | **Dourado** (`#FFE082`) |
| Botão Diagnóstico | **Gradiente coral-laranja** |
| BottomNav | **Inicio, Relatórios, Services, Conta** |

---

## 🎨 Cores e Gradientes

| Elemento | Cores |
|----------|-------|
| Header | `#FF6B6B` → `#FFB66C` → `#56CCF2` |
| Badge Plano | `#FFE082` (dourado) |
| Internet | `#FF8A65` → `#FF5722` |
| Suporte | `#4DD0E1` → `#00ACC1` |
| TV | `#FFD54F` → `#FFC107` |
| Config | `#B39DDB` → `#7E57C2` |
| Diagnóstico | `#FF8A65` → `#FF5722` |
| Accent | `#2D9CDB` (azul-turquesa) |

---

## 📁 Arquivos

### `lib/layouts/layout_07/theme.dart`
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Layout07Theme {
  static const Color headerStart = Color(0xFFFF6B6B);
  static const Color headerMid = Color(0xFFFFB66C);
  static const Color headerEnd = Color(0xFF56CCF2);
  static const Color background = Color(0xFFFFF7EE);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color accent = Color(0xFF2D9CDB);
  static const Color goldBadge = Color(0xFFFFE082);

  static ThemeData getTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      primaryColor: accent,
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent,
        surface: cardBackground,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static LinearGradient headerGradient() => const LinearGradient(
    colors: [headerStart, headerMid, headerEnd],
  );
}
```

### Dashboard Features

- **Header:** Gradiente tropical com WaveClipper
- **Saudação:** "Olá, [Nome]!" em branco
- **Badge:** Plano em dourado com texto marrom
- **Cards lado a lado:** Status (Conectado/Desconectado) e Fatura
- **Grid de Serviços 2x2:** Botões com gradiente (Internet, Suporte, TV, Config)
- **Botão Diagnóstico:** Gradiente coral-laranja com sombra

### BottomNav

```
Inicio → dashboard
Relatórios → internet_usage
Services → invoices
Conta → contract
```

---

## ✅ Git

- Flutter: `467a652` → `main`
- Root: Atualizado → `master`
