"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.defaultThemeConfig = void 0;
exports.isValidHexColor = isValidHexColor;
exports.validateThemeConfig = validateThemeConfig;
exports.mergeThemeConfig = mergeThemeConfig;
exports.defaultThemeConfig = {
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
function isValidHexColor(color) {
    return /^#[0-9A-F]{6}$/i.test(color);
}
function validateThemeConfig(config) {
    var _a, _b;
    const errors = [];
    if (config.colors) {
        Object.entries(config.colors).forEach(([key, value]) => {
            if (value && !isValidHexColor(value)) {
                errors.push(`Cor inválida em colors.${key}: ${value}`);
            }
        });
    }
    if ((_a = config.typography) === null || _a === void 0 ? void 0 : _a.fontSizes) {
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
    if (((_b = config.effects) === null || _b === void 0 ? void 0 : _b.glassOpacity) !== undefined) {
        if (config.effects.glassOpacity < 0 || config.effects.glassOpacity > 1) {
            errors.push(`Opacidade inválida: ${config.effects.glassOpacity}`);
        }
    }
    return { valid: errors.length === 0, errors };
}
function mergeThemeConfig(custom, defaults = exports.defaultThemeConfig) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j;
    return {
        colors: Object.assign(Object.assign({}, defaults.colors), (custom.colors || {})),
        typography: Object.assign(Object.assign(Object.assign({}, defaults.typography), (custom.typography || {})), { fontSizes: Object.assign(Object.assign({}, defaults.typography.fontSizes), (((_a = custom.typography) === null || _a === void 0 ? void 0 : _a.fontSizes) || {})), fontWeights: Object.assign(Object.assign({}, defaults.typography.fontWeights), (((_b = custom.typography) === null || _b === void 0 ? void 0 : _b.fontWeights) || {})), lineHeights: Object.assign(Object.assign({}, defaults.typography.lineHeights), (((_c = custom.typography) === null || _c === void 0 ? void 0 : _c.lineHeights) || {})) }),
        spacing: Object.assign(Object.assign({}, defaults.spacing), (custom.spacing || {})),
        borderRadius: Object.assign(Object.assign({}, defaults.borderRadius), (custom.borderRadius || {})),
        shadows: Object.assign(Object.assign({}, defaults.shadows), (custom.shadows || {})),
        effects: Object.assign(Object.assign({}, defaults.effects), (custom.effects || {})),
        components: {
            buttons: Object.assign(Object.assign({}, defaults.components.buttons), (((_d = custom.components) === null || _d === void 0 ? void 0 : _d.buttons) || {})),
            cards: Object.assign(Object.assign({}, defaults.components.cards), (((_e = custom.components) === null || _e === void 0 ? void 0 : _e.cards) || {})),
            inputs: Object.assign(Object.assign({}, defaults.components.inputs), (((_f = custom.components) === null || _f === void 0 ? void 0 : _f.inputs) || {})),
            appBar: Object.assign(Object.assign({}, defaults.components.appBar), (((_g = custom.components) === null || _g === void 0 ? void 0 : _g.appBar) || {})),
            bottomNav: Object.assign(Object.assign({}, defaults.components.bottomNav), (((_h = custom.components) === null || _h === void 0 ? void 0 : _h.bottomNav) || {})),
        },
        darkMode: Object.assign(Object.assign(Object.assign({}, defaults.darkMode), (custom.darkMode || {})), { darkColors: Object.assign(Object.assign({}, (defaults.darkMode.darkColors || {})), (((_j = custom.darkMode) === null || _j === void 0 ? void 0 : _j.darkColors) || {})) }),
    };
}
//# sourceMappingURL=ThemeConfig.js.map