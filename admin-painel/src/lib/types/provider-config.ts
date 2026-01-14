/**
 * Provider Configuration Types
 * Centralized TypeScript definitions for web admin panel
 */

// ============================================
// Theme Colors
// ============================================

export interface ThemeColors {
    themeColor: string;
    secondaryColor: string;
    backgroundColor: string;
    cardColor: string;
    textColor: string;
    iconColor: string;
    actionColor?: string;
    invoiceColor?: string;
}

// ============================================
// Typography
// ============================================

export type FontFamily =
    | 'Inter'
    | 'Roboto'
    | 'Outfit'
    | 'Poppins'
    | 'Open Sans'
    | 'Montserrat'
    | 'Nunito'
    | 'Lato';

export type FontSize = 'small' | 'medium' | 'large';
export type FontWeight = 'regular' | 'medium' | 'semibold' | 'bold';

export interface Typography {
    fontFamily: FontFamily;
    titleSize: FontSize;
    bodySize: FontSize;
    fontWeight: FontWeight;
}

// ============================================
// Layout Types
// ============================================

export type LayoutType =
    | 'layout_02'
    | 'layout_03'
    | 'layout_04'
    | 'layout_05'
    | 'layout_06';

export type DiagnosticStyle =
    | 'default'
    | 'diagnostic_02'
    | 'diagnostic_03'
    | 'diagnostic_05'
    | 'diagnostic_06'
    | 'diagnostic_07';

export interface LayoutThemes {
    layout_02?: ThemeColors;
    layout_03?: ThemeColors;
    layout_04?: ThemeColors;
    layout_05?: ThemeColors;
    layout_06?: ThemeColors;
}

// ============================================
// Menu Configuration
// ============================================

export interface MenuItem {
    enabled: boolean;
    name: string;
    icon?: string;
}

export interface MenuConfig {
    order: string[];
    items: Record<string, MenuItem>;
}

// ============================================
// Support & Contact
// ============================================

export type ContactType = 'phone' | 'email' | 'address' | 'whatsapp';

export interface SupportContact {
    id: string;
    name: string;
    type: ContactType;
    value: string;
}

export interface SupportConfig {
    contacts: SupportContact[];
    channels: SupportContact[];
}

// ============================================
// Other Settings
// ============================================

export interface OtherConfig {
    useBackgroundImage?: boolean;
    showTvService?: boolean;
    showPhoneService?: boolean;
    privacyPolicyUrl?: string;
    customDomain?: string;
    speedTestUrl?: string;
}

// ============================================
// Social Networks
// ============================================

export interface SocialConfig {
    instagram?: string;
    facebook?: string;
    website?: string;
    whatsapp?: string;
    twitter?: string;
    youtube?: string;
}

// ============================================
// Messages
// ============================================

export interface MessagesConfig {
    welcome?: string;
    invoiceReminder?: string;
}

// ============================================
// Integrations
// ============================================

export interface IntegrationsConfig {
    apiToken?: string;
    appName?: string;
}

// ============================================
// FAQ
// ============================================

export interface FaqItem {
    id: string;
    question: string;
    answer: string;
}

// ============================================
// Features
// ============================================

export type FeaturesConfig = Record<string, boolean>;

// ============================================
// Splash Config
// ============================================

export interface SplashConfig {
    enabled?: boolean;
    logoUrl?: string;
    backgroundColor?: string;
    animation?: 'fade' | 'slide' | 'zoom' | 'none';
    duration?: number;
}

// ============================================
// Notifications / Promotions
// ============================================

export interface NotificationItem {
    id: string;
    title: string;
    message: string;
    createdAt?: unknown;
}

export interface NotificationsConfig {
    list?: NotificationItem[];
}

export interface PromotionItem {
    id: string;
    title: string;
    description?: string;
    imageUrl?: string;
}

export interface PromotionsConfig {
    items?: PromotionItem[];
}

// ============================================
// Dashboard Widgets
// ============================================

export interface DashboardWidget {
    id: string;
    type: string;
    enabled: boolean;
    order?: number;
}

export interface DashboardConfig {
    widgets?: DashboardWidget[];
}

// ============================================
// Strings / Texts
// ============================================

export interface AppStrings {
    hello_prefix?: string;
    plan_prefix?: string;
    logout_label?: string;
    home_tab_title?: string;
    diagnostics_button?: string;
    status_ok_title?: string;
    status_ok_message?: string;
    select_contract_message?: string;
    last_invoice_label?: string;
    view_invoices_label?: string;
    pay_invoice_label?: string;
    promise_payment_label?: string;
    support_title?: string;
    channels_title?: string;
    open_ticket_title?: string;
    terms_title?: string;
    ticket_subjects?: string[];
    layoutThemes?: string; // JSON string for legacy compatibility
}

// ============================================
// Carousel
// ============================================

export interface CarouselImage {
    url: string;
    link?: string;
    title?: string;
}

// ============================================
// Main Provider Config
// ============================================

export interface ProviderConfig {
    // Layout
    layoutType: LayoutType;
    diagnosticStyle?: DiagnosticStyle;

    // Colors (current theme)
    themeColor: string;
    secondaryColor: string;
    backgroundColor?: string;
    cardColor?: string;
    textColor?: string;
    iconColor?: string;
    actionColor?: string;
    invoiceColor?: string;

    // Typography
    typography?: Typography;

    // Images
    logoUrl?: string;
    iconUrl?: string;
    backgroundUrl?: string;

    // Carousel
    imageCarousel?: (string | CarouselImage)[];

    // Menu
    menuConfig?: MenuConfig;

    // Support
    supportContacts?: SupportContact[];
    supportChannels?: SupportContact[];

    // Strings
    strings?: AppStrings;

    // Other
    other?: OtherConfig;

    // Social Networks
    social?: SocialConfig;

    // Messages
    messages?: MessagesConfig;

    // Integrations
    integrations?: IntegrationsConfig;

    // FAQ
    faq?: FaqItem[];

    // Features
    features?: FeaturesConfig;

    // Splash Screen
    splash?: SplashConfig;

    // Notifications
    notifications?: NotificationsConfig;

    // Promotions
    promotions?: PromotionsConfig;

    // Dashboard Builder
    dashboardConfig?: DashboardConfig;

    // Legacy compatibility - allows additional properties\n    // eslint-disable-next-line @typescript-eslint/no-explicit-any\n    [key: string]: any;
}

// ============================================
// Defaults
// ============================================

export const DEFAULT_TYPOGRAPHY: Typography = {
    fontFamily: 'Inter',
    titleSize: 'medium',
    bodySize: 'medium',
    fontWeight: 'medium',
};

export const DEFAULT_THEME_COLORS: Record<LayoutType, ThemeColors> = {
    layout_02: {
        themeColor: '#3182CE',
        secondaryColor: '#63B3ED',
        backgroundColor: '#F7FAFC',
        cardColor: '#FFFFFF',
        textColor: '#1A202C',
        iconColor: '#3182CE',
    },
    layout_03: {
        themeColor: '#00D4FF',
        secondaryColor: '#FF00FF',
        backgroundColor: '#E8EEF5',
        cardColor: '#E8EEF5',
        textColor: '#2D3748',
        iconColor: '#00D4FF',
    },
    layout_04: {
        themeColor: '#0891B2',
        secondaryColor: '#059669',
        backgroundColor: '#0A0A0A',
        cardColor: '#1C1C1E',
        textColor: '#FFFFFF',
        iconColor: '#0891B2',
    },
    layout_05: {
        themeColor: '#00E5FF',
        secondaryColor: '#7C4DFF',
        backgroundColor: '#050810',
        cardColor: '#161B22',
        textColor: '#FFFFFF',
        iconColor: '#00E5FF',
    },
    layout_06: {
        themeColor: '#00BCD4',
        secondaryColor: '#00E676',
        backgroundColor: '#0A0E21',
        cardColor: '#0F1225',
        textColor: '#FFFFFF',
        iconColor: '#00BCD4',
    },
};
