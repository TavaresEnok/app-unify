"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEFAULT_LOGIN_MODERN = exports.DEFAULT_LOGIN_CLASSIC = void 0;
exports.DEFAULT_LOGIN_CLASSIC = {
    style: 'classic',
    showLogo: true,
    logoSize: 40,
    backgroundType: 'solid',
    backgroundColor: '#1E293B',
    backgroundOpacity: 1,
    showCarousel: false,
    quote: 'Bem-vindo!',
    quoteColor: '#FFFFFF',
    showSocialLogin: false,
    loginButtonText: 'Entrar',
    showTerms: true,
};
exports.DEFAULT_LOGIN_MODERN = Object.assign(Object.assign({}, exports.DEFAULT_LOGIN_CLASSIC), { style: 'modern', showCarousel: true, carouselImages: [], showSocialLogin: true, socialProviders: ['google'], backgroundType: 'gradient', backgroundGradient: { colors: ['#667eea', '#764ba2'], angle: 135 } });
//# sourceMappingURL=LoginConfig.js.map