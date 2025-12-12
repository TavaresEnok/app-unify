export type PromotionType = 'discount' | 'upgrade' | 'freebie' | 'trial';
export type PromotionStatus = 'active' | 'scheduled' | 'expired' | 'draft';

export interface Promotion {
  id: string;
  title: string;
  description: string;
  type: PromotionType;
  status: PromotionStatus;
  imageUrl?: string;
  badge?: string;
  badgeColor?: string;
  backgroundColor?: string;
  linkUrl?: string;
  linkLabel?: string;
  startDate: string;
  endDate: string;
  showCountdown: boolean;
  priority: number;
  pinned: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface PromotionsConfig {
  enabled: boolean;
  showInDashboard: boolean;
  maxVisibleInDashboard: number;
  showCountdown: boolean;
  autoRotate: boolean;
  rotationInterval: number;
}

export const DEFAULT_PROMOTIONS_CONFIG: PromotionsConfig = {
  enabled: true,
  showInDashboard: true,
  maxVisibleInDashboard: 3,
  showCountdown: true,
  autoRotate: true,
  rotationInterval: 10,
};

export function createPromotion(
  title: string,
  description: string,
  startDate: Date,
  endDate: Date,
  options?: Partial<Promotion>
): Promotion {
  return {
    id: `promo_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    title,
    description,
    type: 'discount',
    status: 'draft',
    startDate: startDate.toISOString(),
    endDate: endDate.toISOString(),
    showCountdown: true,
    priority: 0,
    pinned: false,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    ...options,
  };
}

export function isPromotionActive(promo: Promotion): boolean {
  const now = new Date();
  const start = new Date(promo.startDate);
  const end = new Date(promo.endDate);
  return promo.status === 'active' && now >= start && now <= end;
}
