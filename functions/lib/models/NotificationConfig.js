"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEFAULT_NOTIFICATION_CONFIG = void 0;
exports.createNotification = createNotification;
exports.DEFAULT_NOTIFICATION_CONFIG = {
    enabled: true,
    showBadge: true,
    maxVisibleInList: 50,
    categories: {
        urgent: { enabled: true, sound: true, color: '#EF4444', icon: 'warning' },
        info: { enabled: true, sound: false, color: '#3B82F6', icon: 'info' },
        promo: { enabled: true, sound: false, color: '#10B981', icon: 'local_offer' },
    },
};
function createNotification(title, message, category = 'info', options) {
    return Object.assign({ id: `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`, title,
        message,
        category, priority: category === 'urgent' ? 'high' : 'normal', dismissible: category !== 'urgent', read: false, createdAt: new Date().toISOString() }, options);
}
//# sourceMappingURL=NotificationConfig.js.map