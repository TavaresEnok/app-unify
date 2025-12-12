import { useState } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Switch } from '@/components/ui/switch';
import { Slider } from '@/components/ui/slider';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { Palette, Type, Sparkles, Layout, Save, RefreshCw, Battery, Signal, Wifi, User, Bell, Home, BarChart2, LifeBuoy } from 'lucide-react';

interface ThemeConfig {
  colors?: Record<string, string>;
  typography?: { fontFamily?: string; fontSizes?: Record<string, number> };
  spacing?: Record<string, number>;
  borderRadius?: Record<string, number>;
  effects?: { enableGlassmorphism?: boolean; enableGradients?: boolean; enableAnimations?: boolean };
}

const DEFAULT_THEME: ThemeConfig = {
  colors: { primary: '#673AB7', secondary: '#9575CD', background: '#F8F9FC', surface: '#FFFFFF', error: '#EF4444', success: '#10B981', warning: '#F59E0B', info: '#3B82F6', textPrimary: '#1E293B', textSecondary: '#64748B' },
  typography: { fontFamily: 'Inter', fontSizes: { h1: 32, h2: 24, h3: 20, body: 14 } },
  spacing: { xs: 4, sm: 8, md: 16, lg: 24, xl: 32 },
  borderRadius: { sm: 4, md: 8, lg: 16, xl: 24 },
  effects: { enableGlassmorphism: true, enableGradients: true, enableAnimations: true },
};

const GOOGLE_FONTS = ['Inter', 'Roboto', 'Poppins', 'Open Sans', 'Lato', 'Montserrat', 'Raleway', 'Ubuntu', 'Nunito'];

export default function ThemeSettings() {
  const { config, setConfig, saveConfig, isSaving } = useSettings();
  const [localTheme, setLocalTheme] = useState<ThemeConfig>(config.theme || DEFAULT_THEME);

  const updateTheme = (path: string[], value: any) => {
    setLocalTheme(prev => {
      const newTheme = { ...prev };
      let current: any = newTheme;
      for (let i = 0; i < path.length - 1; i++) {
        if (!current[path[i]]) current[path[i]] = {};
        current = current[path[i]];
      }
      current[path[path.length - 1]] = value;
      return newTheme;
    });
  };

  const handleSave = async () => {
    const colors = localTheme.colors || {};
    for (const [key, value] of Object.entries(colors)) {
      if (value && !/^#[0-9A-F]{6}$/i.test(value)) {
        toast.error(`Cor inválida em ${key}: ${value}`);
        return;
      }
    }
    setConfig({ ...config, theme: localTheme });
    await saveConfig();
    toast.success('Tema salvo com sucesso!');
  };

  const resetToDefaults = () => {
    if (confirm('Resetar tema para valores padrão?')) {
      setLocalTheme(DEFAULT_THEME);
      toast.info('Tema resetado');
    }
  };

  const renderColorPicker = (label: string, path: string[], description?: string) => {
    const value = path.reduce((obj: any, key) => obj?.[key], localTheme) || '#000000';
    return (
      <div className="space-y-2">
        <Label className="text-sm font-medium">{label}</Label>
        {description && <p className="text-xs text-muted-foreground">{description}</p>}
        <div className="flex gap-2 items-center">
          <Input type="color" value={value} onChange={(e) => updateTheme(path, e.target.value)} className="w-16 h-10 p-1 cursor-pointer" />
          <Input type="text" value={value} onChange={(e) => updateTheme(path, e.target.value)} placeholder="#000000" className="flex-1 font-mono text-sm" />
        </div>
      </div>
    );
  };

  const renderSlider = (label: string, path: string[], min: number, max: number, step: number = 1) => {
    const value = path.reduce((obj: any, key) => obj?.[key], localTheme) || min;
    return (
      <div className="space-y-3">
        <div className="flex justify-between items-center">
          <Label className="text-sm font-medium">{label}</Label>
          <Badge variant="secondary" className="font-mono text-xs px-2 py-1">{value}{step < 1 ? '' : 'px'}</Badge>
        </div>
        <Slider value={[value]} onValueChange={(vals) => updateTheme(path, vals[0])} min={min} max={max} step={step} />
      </div>
    );
  };

  const primaryColor = localTheme.colors?.primary || '#673AB7';
  const secondaryColor = localTheme.colors?.secondary || '#9575CD';
  const backgroundColor = localTheme.colors?.background || '#F8F9FC';
  const surfaceColor = localTheme.colors?.surface || '#FFFFFF';

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="space-y-1">
          <h2 className="text-3xl font-bold tracking-tight flex items-center gap-2">
            <Palette className="h-8 w-8" />
            Configuração de Tema
          </h2>
          <p className="text-muted-foreground">Customize completamente a aparência visual do aplicativo</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={resetToDefaults}>
            <RefreshCw className="h-4 w-4 mr-2" />Resetar
          </Button>
          <Button onClick={handleSave} disabled={isSaving}>
            <Save className="h-4 w-4 mr-2" />{isSaving ? 'Salvando...' : 'Salvar Tema'}
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <Tabs defaultValue="colors">
            <TabsList className="grid w-full grid-cols-4">
              <TabsTrigger value="colors"><Palette className="h-4 w-4 mr-2" />Cores</TabsTrigger>
              <TabsTrigger value="typography"><Type className="h-4 w-4 mr-2" />Tipografia</TabsTrigger>
              <TabsTrigger value="spacing"><Layout className="h-4 w-4 mr-2" />Espaçamento</TabsTrigger>
              <TabsTrigger value="effects"><Sparkles className="h-4 w-4 mr-2" />Efeitos</TabsTrigger>
            </TabsList>

            <TabsContent value="colors" className="space-y-4 mt-4">
              <Card>
                <CardHeader>
                  <CardTitle>Cores Principais</CardTitle>
                  <CardDescription>Cores primárias que definem a identidade visual</CardDescription>
                </CardHeader>
                <CardContent className="grid gap-4 md:grid-cols-2">
                  {renderColorPicker('Cor Primária', ['colors', 'primary'], 'Cor principal do app')}
                  {renderColorPicker('Cor Secundária', ['colors', 'secondary'], 'Cor de apoio')}
                  {renderColorPicker('Fundo Geral', ['colors', 'background'], 'Fundo da tela principal')}
                  {renderColorPicker('Superfície/Cards', ['colors', 'surface'], 'Cor dos cards e superfícies')}
                </CardContent>
              </Card>

              <Card>
                <CardHeader><CardTitle>Cores de Status</CardTitle></CardHeader>
                <CardContent className="grid gap-4 md:grid-cols-2">
                  {renderColorPicker('Sucesso', ['colors', 'success'])}
                  {renderColorPicker('Erro', ['colors', 'error'])}
                  {renderColorPicker('Aviso', ['colors', 'warning'])}
                  {renderColorPicker('Informação', ['colors', 'info'])}
                </CardContent>
              </Card>

              <Card>
                <CardHeader><CardTitle>Cores de Texto</CardTitle></CardHeader>
                <CardContent className="grid gap-4 md:grid-cols-2">
                  {renderColorPicker('Texto Principal', ['colors', 'textPrimary'])}
                  {renderColorPicker('Texto Secundário', ['colors', 'textSecondary'])}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="typography" className="space-y-4 mt-4">
              <Card>
                <CardHeader><CardTitle>Família de Fonte</CardTitle></CardHeader>
                <CardContent>
                  <Select value={localTheme.typography?.fontFamily || 'Inter'} onValueChange={(value) => updateTheme(['typography', 'fontFamily'], value)}>
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>
                      {GOOGLE_FONTS.map(font => <SelectItem key={font} value={font} style={{ fontFamily: font }}>{font}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </CardContent>
              </Card>

              <Card>
                <CardHeader><CardTitle>Tamanhos de Fonte</CardTitle></CardHeader>
                <CardContent className="space-y-4">
                  {renderSlider('Título Grande (H1)', ['typography', 'fontSizes', 'h1'], 20, 48)}
                  {renderSlider('Título Médio (H2)', ['typography', 'fontSizes', 'h2'], 18, 36)}
                  {renderSlider('Corpo do Texto', ['typography', 'fontSizes', 'body'], 12, 20)}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="spacing" className="space-y-4 mt-4">
              <Card>
                <CardHeader><CardTitle>Espaçamentos</CardTitle></CardHeader>
                <CardContent className="space-y-4">
                  {renderSlider('Pequeno (sm)', ['spacing', 'sm'], 4, 24, 2)}
                  {renderSlider('Médio (md)', ['spacing', 'md'], 8, 32, 2)}
                  {renderSlider('Grande (lg)', ['spacing', 'lg'], 16, 48, 2)}
                </CardContent>
              </Card>

              <Card>
                <CardHeader><CardTitle>Bordas</CardTitle></CardHeader>
                <CardContent className="space-y-4">
                  {renderSlider('Pequeno', ['borderRadius', 'sm'], 0, 12)}
                  {renderSlider('Médio', ['borderRadius', 'md'], 4, 20)}
                  {renderSlider('Grande', ['borderRadius', 'lg'], 8, 32)}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="effects" className="space-y-4 mt-4">
              <Card>
                <CardHeader><CardTitle>Efeitos Visuais</CardTitle></CardHeader>
                <CardContent className="space-y-6">
                  <div className="flex items-center justify-between">
                    <Label>Glassmorphism</Label>
                    <Switch checked={localTheme.effects?.enableGlassmorphism ?? true} onCheckedChange={(c) => updateTheme(['effects', 'enableGlassmorphism'], c)} />
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>

        {/* PREVIEW BONITO E TOTALMENTE DINÂMICO */}
        <div className="lg:col-span-1">
          <div className="sticky top-24">
            <div className="flex items-center justify-between mb-4 px-2">
              <h3 className="text-lg font-semibold tracking-tight">Visualização App</h3>
              <span className="text-[10px] uppercase tracking-wider text-muted-foreground bg-muted/50 px-2 py-1 rounded-md font-bold border border-white/5">Preview</span>
            </div>

            <div className="relative mx-auto border-gray-900 bg-gray-900 border-[12px] rounded-[3rem] h-[620px] w-[310px] shadow-2xl ring-1 ring-white/10">
              <div className="w-[100px] h-[22px] bg-gray-900 top-0 rounded-b-[1rem] left-1/2 -translate-x-1/2 absolute z-20 border-b border-x border-gray-800"></div>
              <div className="h-[46px] w-[3px] bg-gray-800 absolute -start-[15px] top-[100px] rounded-s-lg"></div>
              <div className="h-[46px] w-[3px] bg-gray-800 absolute -start-[15px] top-[160px] rounded-s-lg"></div>
              <div className="h-[64px] w-[3px] bg-gray-800 absolute -end-[15px] top-[130px] rounded-e-lg"></div>
              
              <div className="rounded-[2.3rem] overflow-hidden w-full h-full relative flex flex-col font-sans" style={{ backgroundColor }}>
                <style>{`.no-scrollbar::-webkit-scrollbar { display: none; } .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }`}</style>

                {/* Status Bar */}
                <div className="h-10 w-full flex justify-between items-end px-5 pb-1 z-30 text-[10px] font-medium tracking-wide text-white">
                  <span>12:30</span>
                  <div className="flex gap-1.5 items-center opacity-90"><Signal className="h-3 w-3"/><Wifi className="h-3 w-3"/><Battery className="h-3.5 w-3.5"/></div>
                </div>

                {/* HEADER COM GRADIENTE DINÂMICO */}
                <div className="relative shrink-0">
                  <div className="absolute inset-0 opacity-90" style={{ background: `linear-gradient(160deg, ${primaryColor} 0%, ${secondaryColor} 100%)`, borderBottomLeftRadius: '2rem', borderBottomRightRadius: '2rem' }} />
                  
                  <div className="relative z-10 pt-2 pb-6 px-5">
                    <div className="flex justify-between items-start mb-6">
                      <div className="flex items-center gap-3">
                        <div className="h-10 w-10 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center border border-white/20 shadow-sm"><User className="h-5 w-5 text-white"/></div>
                        <div><div className="h-2.5 w-20 bg-white/40 rounded-full mb-1.5"></div><div className="h-2 w-12 bg-white/25 rounded-full"></div></div>
                      </div>
                      <Bell className="h-5 w-5 text-white" />
                    </div>

                    <div className="bg-white/15 backdrop-blur-md rounded-2xl p-4 border border-white/20 shadow-lg">
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
                  <div className="h-3 w-24 bg-slate-200 rounded-full mb-4"></div>
                  
                  <div className="grid grid-cols-2 gap-3">
                    {['Notificações', 'Teste de...', 'Consumo de...', 'Suporte'].map((label, i) => (
                      <div key={i} className="aspect-[1.4/1] rounded-2xl flex flex-col items-center justify-center gap-2 p-2 shadow-sm border border-slate-100" style={{ backgroundColor: surfaceColor }}>
                        <div className="p-2 rounded-xl" style={{ backgroundColor: `${primaryColor}15` }}>
                          {i === 0 && <Bell className="h-5 w-5" style={{ color: primaryColor }} />}
                          {i === 1 && <Home className="h-5 w-5" style={{ color: primaryColor }} />}
                          {i === 2 && <BarChart2 className="h-5 w-5" style={{ color: primaryColor }} />}
                          {i === 3 && <LifeBuoy className="h-5 w-5" style={{ color: primaryColor }} />}
                        </div>
                        <span className="text-[10px] font-medium text-slate-600 text-center leading-tight line-clamp-1 px-1">{label}</span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* BOTTOM NAV */}
                <div className="h-[70px] backdrop-blur-xl border-t border-slate-100 flex justify-around items-center px-4 pb-3 absolute bottom-0 w-full z-40" style={{ backgroundColor: `${surfaceColor}E6` }}>
                  <div className="flex flex-col items-center gap-1">
                    <div className="p-1.5 rounded-xl" style={{ backgroundColor: `${primaryColor}15` }}>
                      <Home className="h-5 w-5" style={{ color: primaryColor }} />
                    </div>
                  </div>
                  <div className="flex flex-col items-center gap-1 opacity-40"><BarChart2 className="h-5 w-5 text-slate-800" /></div>
                  <div className="flex flex-col items-center gap-1 opacity-40"><LifeBuoy className="h-5 w-5 text-slate-800" /></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
