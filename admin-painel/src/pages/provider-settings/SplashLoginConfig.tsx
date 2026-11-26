import { useState } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { toast } from 'sonner';
import { Sparkles, Save } from 'lucide-react';
import { SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

// Mesmos textos e limites do app (unified_login_page.dart / provider_config.dart).
const DEFAULT_LOGIN_HEADLINE = 'Sua internet,\nna palma da mão.';
const DEFAULT_LOGIN_SUBHEADLINE = 'Faturas, Wi-Fi e suporte em um só lugar.';
const LOGIN_HEADLINE_MAX = 80;
const LOGIN_SUBHEADLINE_MAX = 120;
const DEFAULT_SPLASH_COLOR = '#FFFFFF';
const HEX = /^#[0-9a-fA-F]{6}$/;

type LoginSettings = { showHeadline?: boolean; headline?: string; subheadline?: string } & Record<string, unknown>;

export default function SplashLoginConfig() {
  const { config, setConfig, saveConfig, isSaving } = useSettings();
  const [login, setLogin] = useState<LoginSettings>({ showHeadline: true, headline: '', subheadline: '', ...(config.login ?? {}) });
  const [splashColor, setSplashColor] = useState<string>(
    HEX.test(String(config.splash?.backgroundColor ?? '')) ? String(config.splash?.backgroundColor) : DEFAULT_SPLASH_COLOR);
  const splashValid = HEX.test(splashColor);

  const handleSave = async () => {
    if (!splashValid) {
      toast.error('Cor da abertura inválida', { description: 'Use o formato #RRGGBB, por exemplo #FFFFFF.' });
      return;
    }
    const nextConfig = {
      ...config,
      login,
      splash: { ...(config.splash ?? {}), backgroundColor: splashColor.toUpperCase() },
    };
    setConfig(nextConfig);
    await saveConfig(nextConfig);
    toast.success('Configurações salvas!');
  };

  return (
    <SettingsPage
      title="Splash & Login"
      description="A abertura do app e a tela de entrada do assinante."
      icon={Sparkles}
      actions={(
        <Button onClick={handleSave} disabled={isSaving} className="gap-2">
          <Save className="h-4 w-4 mr-2" />
          {isSaving ? 'Salvando...' : 'Salvar'}
        </Button>
      )}
    >
      <SettingsSection
        title="Frase da tela de entrada"
        description="Texto que aparece na faixa colorida do login, abaixo da logo. Vale para apps a partir da versão 1.0.19."
      >
        <div className="space-y-4">
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label htmlFor="login-show-headline">Mostrar frase</Label>
              <p className="text-xs text-muted-foreground">Desligado, a faixa mostra só a logo do provedor.</p>
            </div>
            <Switch
              id="login-show-headline"
              checked={login.showHeadline !== false}
              onCheckedChange={(c) => setLogin({ ...login, showHeadline: c })}
            />
          </div>

          {login.showHeadline !== false && (
            <>
              <div className="space-y-1.5">
                <Label htmlFor="login-headline">Frase principal</Label>
                <Textarea
                  id="login-headline"
                  rows={2}
                  maxLength={LOGIN_HEADLINE_MAX}
                  value={login.headline ?? ''}
                  onChange={(e) => setLogin({ ...login, headline: e.target.value })}
                  placeholder={DEFAULT_LOGIN_HEADLINE}
                />
                <p className="text-xs text-muted-foreground">
                  Até {LOGIN_HEADLINE_MAX} caracteres; use Enter para quebrar a linha. Em branco, o app usa a frase padrão.
                </p>
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="login-subheadline">Texto de apoio</Label>
                <Input
                  id="login-subheadline"
                  maxLength={LOGIN_SUBHEADLINE_MAX}
                  value={login.subheadline ?? ''}
                  onChange={(e) => setLogin({ ...login, subheadline: e.target.value })}
                  placeholder={DEFAULT_LOGIN_SUBHEADLINE}
                />
                <p className="text-xs text-muted-foreground">
                  Até {LOGIN_SUBHEADLINE_MAX} caracteres. Em branco, o app usa o texto padrão.
                </p>
              </div>
              <div className="rounded-xl p-5 text-center text-white" style={{ backgroundColor: config.themeColor || '#2456C9' }}>
                <p className="text-xs opacity-75 mb-2">Prévia</p>
                <p className="text-2xl font-extrabold leading-tight whitespace-pre-line">
                  {(login.headline ?? '').trim() || DEFAULT_LOGIN_HEADLINE}
                </p>
                <p className="text-sm opacity-80 mt-2">
                  {(login.subheadline ?? '').trim() || DEFAULT_LOGIN_SUBHEADLINE}
                </p>
              </div>
            </>
          )}
        </div>
      </SettingsSection>

      <SettingsSection
        title="Abertura do app (splash)"
        description="Tela que aparece enquanto o app carrega: a logo do provedor sobre esta cor. Entra no próximo app gerado em Gerar app."
      >
        <div className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="splash-color">Cor de fundo</Label>
            <div className="flex gap-2">
              <Input
                type="color"
                aria-label="Escolher cor de fundo"
                value={splashValid ? splashColor : DEFAULT_SPLASH_COLOR}
                onChange={(e) => setSplashColor(e.target.value.toUpperCase())}
                className="w-16 p-1"
              />
              <Input
                id="splash-color"
                value={splashColor}
                onChange={(e) => setSplashColor(e.target.value.trim())}
                maxLength={7}
                className="flex-1 font-mono"
                aria-invalid={!splashValid}
              />
              <Button type="button" variant="outline" onClick={() => setSplashColor(DEFAULT_SPLASH_COLOR)}>Branco</Button>
            </div>
            {!splashValid && <p className="text-xs text-destructive">Use o formato #RRGGBB.</p>}
            <p className="text-xs text-muted-foreground">
              Escolha uma cor em que a logo apareça bem. Logos escuras pedem fundo claro.
            </p>
          </div>
          <div className="flex justify-center">
            <div
              className="flex h-56 w-32 items-center justify-center rounded-2xl border border-[#EEF0F4] shadow-sm"
              style={{ backgroundColor: splashValid ? splashColor : DEFAULT_SPLASH_COLOR }}
            >
              {config.logoUrl
                ? <img src={config.logoUrl} alt="Logo na abertura" className="max-h-16 max-w-[80%] object-contain" />
                : <span className="text-xs text-muted-foreground">Sem logo</span>}
            </div>
          </div>
        </div>
      </SettingsSection>
    </SettingsPage>
  );
}
