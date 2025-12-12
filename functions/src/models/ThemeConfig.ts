export interface ThemeConfig {
  colors: {
    primary: string;
    secondary: string;
    background: string;
    surface: string;
    error: string;
    success: string;
    warning: string;
    info: string;
    invoice: string;
    action: string;
    link: string;
    textPrimary: string;
    textSecondary: string;
    textHint: string;
    cardBackground: string;
    cardText: string;
  };

  typography: {
    fontFamily: string;
    fontSizes: {
      h1: number;
      h2: number;
      h3: number;
      body: number;
      caption: number;
      button: number;
    };
    fontWeights: {
      light: string;
      regular: string;
      medium: string;
      semibold: string;
      bold: string;
    };
    lineHeights: {
      tight: number;
      normal: number;
      relaxed: number;
    };
  };

  spacing: {
    xs: number;
    sm: number;
    md: number;
    lg: number;
    xl: number;
    xxl: number;
  };

  borderRadius: {
    none: number;
    sm: number;
    md: number;
    lg: number;
    xl: number;
    full: number;
  };

  shadows: {
    enabled: boolean;
    sm: string;
    md: string;
    lg: string;
    xl: string;
  };

  effects: {
    enableGlassmorphism: boolean;
    enableGradients: boolean;
    enableAnimations: boolean;
    animationSpeed: "slow" | "normal" | "fast";
    glassOpacity: number;
    glassBlur: number;
  };

  components: {
    buttons: {
      borderRadius: number;
      elevation: number;
      padding: { horizontal: number; vertical: number };
    };
    cards: {
      borderRadius: number;
      elevation: number;
      padding: number;
      enableBorder: boolean;
      borderColor?: string;
      borderWidth?: number;
    };
    inputs: {
      borderRadius: number;
      height: number;
      padding: number;
      borderWidth: number;
      borderColor: string;
      focusBorderColor: string;
    };
    appBar: {
      height: number;
      elevation: number;
      backgroundColor?: string;
      centerTitle: boolean;
    };
    bottomNav: {
      height: number;
      elevation: number;
      backgroundColor?: string;
      selectedItemColor?: string;
      unselectedItemColor?: string;
      showLabels: boolean;
    };
  };

  darkMode: {
    enabled: boolean;
    defaultMode: "light" | "dark" | "auto";
    followSystem: boolean;
    darkColors?: {
      primary?: string;
      secondary?: string;
      background?: string;
      surface?: string;
      textPrimary?: string;
      textSecondary?: string;
    };
  };
}

export const defaultThemeConfig: ThemeConfig = {
  colors: {
    primary: "#673AB7",
    secondary: "#9575CD",
    background: "#0F172A",
    surface: "#1E293B",
    error: "#EF4444",
    success: "#10B981",
    warning: "#F59E0B",
    info: "#3B82F6",
    invoice: "#10B981",
    action: "#E11D48",
    link: "#3B82F6",
    textPrimary: "#FFFFFF",
    textSecondary: "#94A3B8",
    textHint: "#64748B",
    cardBackground: "#F8F8F8",
    cardText: "#333333",
  },
  typography: {
    fontFamily: "Inter",
    fontSizes: { h1: 32, h2: 24, h3: 20, body: 14, caption: 12, button: 14 },
    fontWeights: { light: "300", regular: "400", medium: "500", semibold: "600", bold: "700" },
    lineHeights: { tight: 1.2, normal: 1.5, relaxed: 1.75 },
  },
  spacing: { xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48 },
  borderRadius: { none: 0, sm: 4, md: 8, lg: 16, xl: 24, full: 9999 },
  shadows: {
    enabled: true,
    sm: "0 1px 2px 0 rgba(0, 0, 0, 0.05)",
    md: "0 4px 6px -1px rgba(0, 0, 0, 0.1)",
    lg: "0 10px 15px -3px rgba(0, 0, 0, 0.1)",
    xl: "0 20px 25px -5px rgba(0, 0, 0, 0.1)",
  },
  effects: {
    enableGlassmorphism: true,
    enableGradients: true,
    enableAnimations: true,
    animationSpeed: "normal",
    glassOpacity: 0.7,
    glassBlur: 12,
  },
  components: {
    buttons: { borderRadius: 18, elevation: 2, padding: { horizontal: 24, vertical: 14 } },
    cards: { borderRadius: 16, elevation: 2, padding: 16, enableBorder: false, borderColor: "#E2E8F0", borderWidth: 1 },
    inputs: { borderRadius: 12, height: 48, padding: 12, borderWidth: 1, borderColor: "#E2E8F0", focusBorderColor: "#673AB7" },
    appBar: { height: 56, elevation: 0, backgroundColor: undefined, centerTitle: true },
    bottomNav: { height: 74, elevation: 8, backgroundColor: undefined, selectedItemColor: undefined, unselectedItemColor: undefined, showLabels: false },
  },
  darkMode: {
    enabled: true,
    defaultMode: "auto",
    followSystem: true,
    darkColors: { background: "#0F172A", surface: "#1E293B", textPrimary: "#F8FAFC", textSecondary: "#94A3B8" },
  },
};

export function isValidHexColor(color: string): boolean {
  return /^#[0-9A-F]{6}$/i.test(color);
}

export function validateThemeConfig(config: Partial<ThemeConfig>): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  
  if (config.colors) {
    Object.entries(config.colors).forEach(([key, value]) => {
      if (value && !isValidHexColor(value)) {
        errors.push(`Cor inválida em colors.${key}: ${value}`);
      }
    });
  }
  
  if (config.typography?.fontSizes) {
    Object.entries(config.typography.fontSizes).forEach(([key, value]) => {
      if (value && (value < 8 || value > 72)) {
        errors.push(`Tamanho de fonte inválido em typography.fontSizes.${key}: ${value}`);
      }
    });
  }
  
  if (config.spacing) {
    Object.entries(config.spacing).forEach(([key, value]) => {
      if (value && (value < 0 || value > 200)) {
        errors.push(`Espaçamento inválido em spacing.${key}: ${value}`);
      }
    });
  }
  
  if (config.effects?.glassOpacity !== undefined) {
    if (config.effects.glassOpacity < 0 || config.effects.glassOpacity > 1) {
      errors.push(`Opacidade inválida: ${config.effects.glassOpacity}`);
    }
  }
  
  return { valid: errors.length === 0, errors };
}

export function mergeThemeConfig(custom: Partial<ThemeConfig>, defaults: ThemeConfig = defaultThemeConfig): ThemeConfig {
  return {
    colors: { ...defaults.colors, ...(custom.colors || {}) },
    typography: {
      ...defaults.typography,
      ...(custom.typography || {}),
      fontSizes: { ...defaults.typography.fontSizes, ...(custom.typography?.fontSizes || {}) },
      fontWeights: { ...defaults.typography.fontWeights, ...(custom.typography?.fontWeights || {}) },
      lineHeights: { ...defaults.typography.lineHeights, ...(custom.typography?.lineHeights || {}) },
    },
    spacing: { ...defaults.spacing, ...(custom.spacing || {}) },
    borderRadius: { ...defaults.borderRadius, ...(custom.borderRadius || {}) },
    shadows: { ...defaults.shadows, ...(custom.shadows || {}) },
    effects: { ...defaults.effects, ...(custom.effects || {}) },
    components: {
      buttons: { ...defaults.components.buttons, ...(custom.components?.buttons || {}) },
      cards: { ...defaults.components.cards, ...(custom.components?.cards || {}) },
      inputs: { ...defaults.components.inputs, ...(custom.components?.inputs || {}) },
      appBar: { ...defaults.components.appBar, ...(custom.components?.appBar || {}) },
      bottomNav: { ...defaults.components.bottomNav, ...(custom.components?.bottomNav || {}) },
    },
    darkMode: {
      ...defaults.darkMode,
      ...(custom.darkMode || {}),
      darkColors: { ...(defaults.darkMode.darkColors || {}), ...(custom.darkMode?.darkColors || {}) },
    },
  };
}
