export type NotificationCategory = 'urgent' | 'info' | 'promo';
export type NotificationPriority = 'low' | 'normal' | 'high';

export interface InAppNotification {
  id: string;
  title: string;
  message: string;
  category: NotificationCategory;
  priority: NotificationPriority;
  icon?: string;
  imageUrl?: string;
  actionLabel?: string;
  actionUrl?: string;
  dismissible: boolean;
  read: boolean;
  createdAt: string;
  expiresAt?: string;
}

export interface NotificationConfig {
  enabled: boolean;
  showBadge: boolean;
  maxVisibleInList: number;
  categories: {
    [K in NotificationCategory]: {
      enabled: boolean;
      sound: boolean;
      color: string;
      icon: string;
    };
  };
}

export const DEFAULT_NOTIFICATION_CONFIG: NotificationConfig = {
  enabled: true,
  showBadge: true,
  maxVisibleInList: 50,
  categories: {
    urgent: { enabled: true, sound: true, color: '#EF4444', icon: 'warning' },
    info: { enabled: true, sound: false, color: '#3B82F6', icon: 'info' },
    promo: { enabled: true, sound: false, color: '#10B981', icon: 'local_offer' },
  },
};

export function createNotification(
  title: string,
  message: string,
  category: NotificationCategory = 'info',
  options?: Partial<InAppNotification>
): InAppNotification {
  return {
    id: `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    title,
    message,
    category,
    priority: category === 'urgent' ? 'high' : 'normal',
    dismissible: category !== 'urgent',
    read: false,
    createdAt: new Date().toISOString(),
    ...options,
  };
}
