export type LoginStyle = 'classic' | 'modern' | 'minimal';
export type BackgroundType = 'solid' | 'gradient' | 'image';

export interface LoginConfig {
  style: LoginStyle;
  showLogo: boolean;
  logoUrl?: string;
  logoSize: number;
  backgroundType: BackgroundType;
  backgroundColor?: string;
  backgroundGradient?: { colors: string[]; angle: number };
  backgroundImage?: string;
  backgroundOpacity: number;
  showCarousel: boolean;
  carouselImages?: string[];
  quote?: string;
  quoteColor?: string;
  showSocialLogin: boolean;
  socialProviders?: Array<'google' | 'facebook' | 'apple'>;
  loginButtonText: string;
  showTerms: boolean;
}

export const DEFAULT_LOGIN_CLASSIC: LoginConfig = {
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

export const DEFAULT_LOGIN_MODERN: LoginConfig = {
  ...DEFAULT_LOGIN_CLASSIC,
  style: 'modern',
  showCarousel: true,
  carouselImages: [],
  showSocialLogin: true,
  socialProviders: ['google'],
  backgroundType: 'gradient',
  backgroundGradient: { colors: ['#667eea', '#764ba2'], angle: 135 },
};
