export type SplashAnimation = 'fade' | 'scale' | 'slide' | 'bounce' | 'rotate';

export interface SplashConfig {
  enabled: boolean;
  logoUrl: string;
  backgroundColor: string;
  animation: SplashAnimation;
  duration: number;
  showProgressBar: boolean;
  progressBarColor?: string;
  loadingText?: string;
  loadingTextColor?: string;
  showAppVersion: boolean;
  minimumDisplayTime: number;
  fadeOutDuration: number;
}

export const DEFAULT_SPLASH_CONFIG: SplashConfig = {
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

export function validateSplashConfig(config: SplashConfig): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  if (!config.logoUrl) errors.push('logoUrl é obrigatório');
  if (config.duration < 500 || config.duration > 10000) errors.push('duration deve estar entre 500 e 10000ms');
  if (config.minimumDisplayTime < 0 || config.minimumDisplayTime > config.duration) {
    errors.push('minimumDisplayTime deve ser menor que duration');
  }
  return { valid: errors.length === 0, errors };
}
