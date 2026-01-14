import { useContext, useMemo } from 'react';
import { SettingsContext } from '@/contexts/SettingsContext';
import { Battery, Signal, Wifi, User, Bell } from 'lucide-react';
import { Home, BarChart2, LifeBuoy, FileText, Lock, Zap, Globe, HelpCircle, Lightbulb, Share2, Image as ImageIcon } from 'lucide-react';

// Layout theme configurations matching Flutter app
const LAYOUT_THEMES: Record<string, {
    background: string;
    cardBackground: string;
    textColor: string;
    textMuted: string;
    isDark: boolean;
    style: 'light' | 'dark' | 'neumorphic';
}> = {
    layout_02: {
        background: '#F7FAFC',
        cardBackground: '#FFFFFF',
        textColor: '#1A202C',
        textMuted: '#718096',
        isDark: false,
        style: 'light',
    },
    layout_03: {
        background: '#E8EEF5',
        cardBackground: '#E8EEF5',
        textColor: '#2D3748',
        textMuted: '#718096',
        isDark: false,
        style: 'neumorphic',
    },
    layout_04: {
        background: '#0A0A0A',
        cardBackground: '#1C1C1E',
        textColor: '#FFFFFF',
        textMuted: '#A0AEC0',
        isDark: true,
        style: 'dark',
    },
    layout_05: {
        background: '#050810',
        cardBackground: '#161B22',
        textColor: '#FFFFFF',
        textMuted: '#A0AEC0',
        isDark: true,
        style: 'dark',
    },
    layout_06: {
        background: '#0A0E21',
        cardBackground: '#0F1225',
        textColor: '#FFFFFF',
        textMuted: '#A0AEC0',
        isDark: true,
        style: 'dark',
    },
};

export default function MobilePreview() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config } = context;

    const layoutType = config.layoutType || 'layout_06';
    const theme = LAYOUT_THEMES[layoutType] || LAYOUT_THEMES.layout_06;

    const primaryColor = config.themeColor || '#673AB7';
    const secondaryColor = config.secondaryColor || '#9575CD';
    const backgroundColor = config.backgroundColor || theme.background;
    const cardColor = config.cardColor || theme.cardBackground;
    const textColor = config.textColor || theme.textColor;

    // Verifica se deve usar imagem
    const useBackgroundImage = config.other?.useBackgroundImage || false;

    const rawFirstImage = config.imageCarousel?.[0];
    let headerImageUrl: string | null = null;
    if (typeof rawFirstImage === 'string') {
        headerImageUrl = rawFirstImage;
    } else if (typeof rawFirstImage === 'object' && rawFirstImage?.url) {
        headerImageUrl = rawFirstImage.url;
    }

    const getIcon = (id: string) => {
        const icons: any = {
            'home': Home, 'internet_usage': BarChart2, 'support': LifeBuoy,
            'invoices': FileText, 'payment_promise': Lock, 'speed_test': Zap,
            'notifications': Bell, 'faq': HelpCircle, 'useful_tips': Lightbulb,
            'social': Share2, 'website': Globe
        };
        return icons[id] || Home;
    };

    const menuOrder = config.menuConfig?.order || ['invoices', 'internet_usage', 'support', 'speed_test'];
    const menuItems = config.menuConfig?.items || {};

    // Layout name for badge
    const layoutName = useMemo(() => {
        const names: Record<string, string> = {
            layout_02: 'Light',
            layout_03: 'Neumorphic',
            layout_04: 'Obsidian Dark',
            layout_05: 'Cyber Neon',
            layout_06: 'Clean Dark',
        };
        return names[layoutType] || 'Custom';
    }, [layoutType]);

    // Neumorphic shadow style
    const neumorphicShadow = theme.style === 'neumorphic'
        ? { boxShadow: '6px 6px 12px rgba(0,0,0,0.08), -6px -6px 12px rgba(255,255,255,0.8)' }
        : {};

    return (
        <div className="sticky top-24">
            <div className="flex items-center justify-between mb-4 px-2">
                <h3 className="text-lg font-semibold tracking-tight">Visualização App</h3>
                <span
                    className="text-[10px] uppercase tracking-wider px-2 py-1 rounded-md font-bold border"
                    style={{
                        backgroundColor: theme.isDark ? '#1C1C1E' : '#F7FAFC',
                        color: theme.isDark ? '#FFFFFF' : '#1A202C',
                        borderColor: theme.isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)',
                    }}
                >
                    {layoutName}
                </span>
            </div>

            <div className="relative mx-auto border-gray-900 bg-gray-900 border-[12px] rounded-[3rem] h-[620px] w-[310px] shadow-2xl ring-1 ring-white/10">
                <div className="w-[100px] h-[22px] bg-gray-900 top-0 rounded-b-[1rem] left-1/2 -translate-x-1/2 absolute z-20 border-b border-x border-gray-800"></div>
                {/* Botões laterais */}
                <div className="h-[46px] w-[3px] bg-gray-800 absolute -start-[15px] top-[100px] rounded-s-lg"></div>
                <div className="h-[46px] w-[3px] bg-gray-800 absolute -start-[15px] top-[160px] rounded-s-lg"></div>
                <div className="h-[64px] w-[3px] bg-gray-800 absolute -end-[15px] top-[130px] rounded-e-lg"></div>

                {/* TELA: Fundo dinâmico por layout */}
                <div
                    className="rounded-[2.3rem] overflow-hidden w-full h-full relative flex flex-col font-sans selection:bg-transparent"
                    style={{ backgroundColor }}
                >
                    <style>{`.no-scrollbar::-webkit-scrollbar { display: none; } .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }`}</style>

                    {/* Status Bar */}
                    <div
                        className="h-10 w-full flex justify-between items-end px-5 pb-1 z-30 text-[10px] font-medium tracking-wide"
                        style={{ color: theme.isDark || useBackgroundImage ? '#FFFFFF' : '#0F172A' }}
                    >
                        <span>12:30</span>
                        <div className="flex gap-1.5 items-center opacity-90">
                            <Signal className="h-3 w-3" />
                            <Wifi className="h-3 w-3" />
                            <Battery className="h-3.5 w-3.5" />
                        </div>
                    </div>

                    {/* HEADER */}
                    <div className="relative shrink-0">
                        {useBackgroundImage && headerImageUrl ? (
                            <div className="absolute inset-0 border-b-2 border-white/5" style={{ borderBottomLeftRadius: '2rem', borderBottomRightRadius: '2rem', overflow: 'hidden' }}>
                                <img src={headerImageUrl} className="w-full h-full object-cover" alt="Header" />
                                <div className="absolute inset-0 bg-black/40 backdrop-blur-[1px]"></div>
                            </div>
                        ) : (
                            <div
                                className="absolute inset-0 opacity-90"
                                style={{
                                    background: theme.style === 'neumorphic'
                                        ? `linear-gradient(160deg, ${primaryColor} 0%, ${secondaryColor} 100%)`
                                        : `linear-gradient(160deg, ${primaryColor} 0%, ${secondaryColor} 100%)`,
                                    borderBottomLeftRadius: '2rem',
                                    borderBottomRightRadius: '2rem'
                                }}
                            />
                        )}

                        <div className="relative z-10 pt-2 pb-6 px-5">
                            <div className="flex justify-between items-start mb-6">
                                <div className="flex items-center gap-3">
                                    <div className="h-10 w-10 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center border border-white/20 shadow-sm">
                                        <User className="h-5 w-5 text-white" />
                                    </div>
                                    <div>
                                        <div className="h-2.5 w-20 bg-white/40 rounded-full mb-1.5"></div>
                                        <div className="h-2 w-12 bg-white/25 rounded-full"></div>
                                    </div>
                                </div>
                                <Bell className="h-5 w-5 text-white" />
                            </div>

                            {/* Fatura Card */}
                            <div className="bg-white/15 backdrop-blur-md rounded-2xl p-4 border border-white/20 shadow-lg relative overflow-hidden">
                                <div className="flex justify-between items-center mb-3">
                                    <div className="h-2 w-16 bg-white/50 rounded-full"></div>
                                    <div className="h-5 w-16 bg-emerald-500/30 border border-emerald-400/50 rounded-full"></div>
                                </div>
                                <div className="h-7 w-28 bg-white/90 rounded-md mb-2"></div>
                                <div className="h-2 w-24 bg-white/40 rounded-full"></div>
                            </div>
                        </div>
                    </div>

                    {/* CONTEÚDO */}
                    <div className="flex-1 overflow-y-auto no-scrollbar p-5 -mt-2 relative z-20">
                        <div
                            className="h-3 w-24 rounded-full mb-4"
                            style={{ backgroundColor: theme.isDark ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.1)' }}
                        ></div>

                        <div className="grid grid-cols-2 gap-3 mb-6">
                            {menuOrder.map((id: string) => {
                                const item = menuItems[id];
                                if (item && !item.enabled) return null;
                                const IconComp = getIcon(id);
                                const label = item?.name || id;

                                return (
                                    <div
                                        key={id}
                                        className="aspect-[1.4/1] rounded-2xl flex flex-col items-center justify-center gap-2 p-2"
                                        style={{
                                            backgroundColor: cardColor,
                                            border: theme.isDark
                                                ? '1px solid rgba(255,255,255,0.1)'
                                                : '1px solid rgba(0,0,0,0.05)',
                                            ...neumorphicShadow,
                                        }}
                                    >
                                        <div
                                            className="p-2 rounded-xl"
                                            style={{ backgroundColor: `${primaryColor}15` }}
                                        >
                                            <IconComp className="h-5 w-5" style={{ color: primaryColor }} />
                                        </div>
                                        <span
                                            className="text-[10px] font-medium text-center leading-tight line-clamp-1 px-1"
                                            style={{ color: textColor }}
                                        >
                                            {label}
                                        </span>
                                    </div>
                                );
                            })}
                        </div>

                        {!useBackgroundImage && (
                            <div
                                className="relative w-full aspect-[2.5/1] rounded-2xl overflow-hidden flex items-center justify-center group"
                                style={{
                                    backgroundColor: cardColor,
                                    border: theme.isDark
                                        ? '1px solid rgba(255,255,255,0.1)'
                                        : '1px solid rgba(0,0,0,0.05)',
                                    ...neumorphicShadow,
                                }}
                            >
                                <div className="flex flex-col items-center gap-2" style={{ color: theme.textMuted }}>
                                    <ImageIcon className="h-8 w-8" />
                                    <span className="text-[10px] uppercase tracking-widest">Carrossel</span>
                                </div>
                            </div>
                        )}
                        <div className="h-10"></div>
                    </div>

                    {/* BOTTOM NAV */}
                    <div
                        className="h-[70px] backdrop-blur-xl border-t flex justify-around items-center px-4 pb-3 absolute bottom-0 w-full z-40"
                        style={{
                            backgroundColor: theme.isDark ? 'rgba(15,18,37,0.9)' : 'rgba(255,255,255,0.9)',
                            borderColor: theme.isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)',
                        }}
                    >
                        <div className="flex flex-col items-center gap-1 cursor-pointer">
                            <div className="p-1.5 rounded-xl" style={{ backgroundColor: `${primaryColor}15` }}>
                                <Home className="h-5 w-5" style={{ color: primaryColor }} />
                            </div>
                        </div>
                        <div className="flex flex-col items-center gap-1 opacity-40">
                            <BarChart2 className="h-5 w-5" style={{ color: textColor }} />
                        </div>
                        <div className="flex flex-col items-center gap-1 opacity-40">
                            <LifeBuoy className="h-5 w-5" style={{ color: textColor }} />
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
