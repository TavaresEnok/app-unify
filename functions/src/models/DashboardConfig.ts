export type WidgetType = 'stats_card' | 'banner' | 'action_grid' | 'carousel' | 'chart' | 'announcements' | 'quick_pay' | 'speed_test' | 'usage_meter';

export interface BaseWidget {
  id: string;
  type: WidgetType;
  position: number;
  visible: boolean;
  title?: string;
  config: any;
}

export interface DashboardConfig {
  widgets: BaseWidget[];
  layout: 'single_column' | 'two_column' | 'grid';
  backgroundColor?: string;
  enablePullToRefresh: boolean;
  showWelcomeMessage: boolean;
  welcomeMessage?: string;
}

export const DEFAULT_DASHBOARD: DashboardConfig = {
  widgets: [],
  layout: 'single_column',
  enablePullToRefresh: true,
  showWelcomeMessage: true,
  welcomeMessage: 'Olá! Bem-vindo',
};

export function validateDashboardConfig(config: DashboardConfig): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
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

export function sortWidgetsByPosition(widgets: BaseWidget[]): BaseWidget[] {
  return [...widgets].sort((a, b) => a.position - b.position);
}

export function getVisibleWidgets(widgets: BaseWidget[]): BaseWidget[] {
  return widgets.filter(w => w.visible);
}
