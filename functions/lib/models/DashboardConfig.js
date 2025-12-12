"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEFAULT_DASHBOARD = void 0;
exports.validateDashboardConfig = validateDashboardConfig;
exports.sortWidgetsByPosition = sortWidgetsByPosition;
exports.getVisibleWidgets = getVisibleWidgets;
exports.DEFAULT_DASHBOARD = {
    widgets: [],
    layout: 'single_column',
    enablePullToRefresh: true,
    showWelcomeMessage: true,
    welcomeMessage: 'Olá! Bem-vindo',
};
function validateDashboardConfig(config) {
    const errors = [];
    if (!config.widgets || !Array.isArray(config.widgets)) {
        errors.push('widgets deve ser um array');
    }
    const positions = config.widgets.map(w => w.position);
    const duplicates = positions.filter((p, i) => positions.indexOf(p) !== i);
    if (duplicates.length > 0) {
        errors.push(`Posições duplicadas: ${duplicates.join(', ')}`);
    }
    return { valid: errors.length === 0, errors };
}
function sortWidgetsByPosition(widgets) {
    return [...widgets].sort((a, b) => a.position - b.position);
}
function getVisibleWidgets(widgets) {
    return widgets.filter(w => w.visible);
}
//# sourceMappingURL=DashboardConfig.js.map