"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEFAULT_SPLASH_CONFIG = void 0;
exports.validateSplashConfig = validateSplashConfig;
exports.DEFAULT_SPLASH_CONFIG = {
    enabled: true,
    logoUrl: '',
    backgroundColor: '#1E293B',
    animation: 'fade',
    duration: 2000,
    showProgressBar: true,
    progressBarColor: '#673AB7',
    loadingText: 'Carregando...',
    loadingTextColor: '#FFFFFF',
    showAppVersion: true,
    minimumDisplayTime: 1500,
    fadeOutDuration: 500,
};
function validateSplashConfig(config) {
    const errors = [];
    if (!config.logoUrl)
        errors.push('logoUrl é obrigatório');
    if (config.duration < 500 || config.duration > 10000)
        errors.push('duration deve estar entre 500 e 10000ms');
    if (config.minimumDisplayTime < 0 || config.minimumDisplayTime > config.duration) {
        errors.push('minimumDisplayTime deve ser menor que duration');
    }
    return { valid: errors.length === 0, errors };
}
//# sourceMappingURL=SplashConfig.js.map