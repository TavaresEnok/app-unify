"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEFAULT_PROMOTIONS_CONFIG = void 0;
exports.createPromotion = createPromotion;
exports.isPromotionActive = isPromotionActive;
exports.DEFAULT_PROMOTIONS_CONFIG = {
    enabled: true,
    showInDashboard: true,
    maxVisibleInDashboard: 3,
    showCountdown: true,
    autoRotate: true,
    rotationInterval: 10,
};
function createPromotion(title, description, startDate, endDate, options) {
    return Object.assign({ id: `promo_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`, title,
        description, type: 'discount', status: 'draft', startDate: startDate.toISOString(), endDate: endDate.toISOString(), showCountdown: true, priority: 0, pinned: false, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() }, options);
}
function isPromotionActive(promo) {
    const now = new Date();
    const start = new Date(promo.startDate);
    const end = new Date(promo.endDate);
    return promo.status === 'active' && now >= start && now <= end;
}
//# sourceMappingURL=PromotionConfig.js.map