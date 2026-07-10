import { useState } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Slider } from '@/components/ui/slider';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { Sparkles, LogIn, Save } from 'lucide-react';
import { SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

export default function SplashLoginConfig() {
  const { config, setConfig, saveConfig, isSaving } = useSettings();
  
  const [splash, setSplash] = useState(config.splash || {
    enabled: true,
    logoUrl: '',
    backgroundColor: '#1E293B',
    animation: 'fade',
    duration: 2000,
    showProgressBar: true,
    progressBarColor: '#673AB7',
  });

  const [login, setLogin] = useState(config.login || {
    style: 'modern',
    showLogo: true,
    backgroundType: 'gradient',
    quote: 'Bem-vindo!',
  });

  const handleSave = async () => {
    setConfig({ ...config, splash, login });
    await saveConfig();
    toast.success('Configurações salvas!');
  };

  return (
    <SettingsPage
      title="Splash & Login"
      description="Configure a primeira impressão do app."
      icon={Sparkles}
      actions={(
        <Button onClick={handleSave} disabled={isSaving} className="gap-2">
          <Save className="h-4 w-4 mr-2" />
          {isSaving ? 'Salvando...' : 'Salvar'}
        </Button>
      )}
    >

      <Tabs defaultValue="splash">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="splash">Splash Screen</TabsTrigger>
          <TabsTrigger value="login">Login Screen</TabsTrigger>
        </TabsList>

        <TabsContent value="splash" className="space-y-4">
          <SettingsSection title="Splash Screen" description="Logo, animação e tempo de abertura do app.">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Label>Habilitar Splash</Label>
                <Switch
                  checked={splash.enabled}
                  onCheckedChange={(c) => setSplash({ ...splash, enabled: c })}
                />
              </div>

              {splash.enabled && (
                <>
                  <div>
                    <Label>URL do Logo</Label>
                    <Input
                      value={splash.logoUrl}
                      onChange={(e) => setSplash({ ...splash, logoUrl: e.target.value })}
                      placeholder="https://..."
                    />
                  </div>

                  <div>
                    <Label>Cor de Fundo</Label>
                    <div className="flex gap-2">
                      <Input
                        type="color"
                        value={splash.backgroundColor}
                        onChange={(e) => setSplash({ ...splash, backgroundColor: e.target.value })}
                        className="w-16"
                      />
                      <Input
                        value={splash.backgroundColor}
                        onChange={(e) => setSplash({ ...splash, backgroundColor: e.target.value })}
                        className="flex-1"
                      />
                    </div>
                  </div>

                  <div>
                    <Label>Animação</Label>
                    <Select
                      value={splash.animation}
                      onValueChange={(v) => setSplash({ ...splash, animation: v })}
                    >
                      <SelectTrigger><SelectValue /></SelectTrigger>
                      <SelectContent>
                        <SelectItem value="fade">Fade In</SelectItem>
                        <SelectItem value="scale">Scale Up</SelectItem>
                        <SelectItem value="slide">Slide Up</SelectItem>
                        <SelectItem value="bounce">Bounce</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div>
                    <div className="flex justify-between items-center mb-2">
                      <Label>Duração</Label>
                      <Badge>{splash.duration}ms</Badge>
                    </div>
                    <Slider
                      value={[splash.duration]}
                      onValueChange={([v]) => setSplash({ ...splash, duration: v })}
                      min={500}
                      max={5000}
                      step={100}
                    />
                  </div>

                  <div className="flex items-center justify-between">
                    <Label>Mostrar Barra de Progresso</Label>
                    <Switch
                      checked={splash.showProgressBar}
                      onCheckedChange={(c) => setSplash({ ...splash, showProgressBar: c })}
                    />
                  </div>
                </>
              )}
            </div>
          </SettingsSection>
        </TabsContent>

        <TabsContent value="login" className="space-y-4">
          <SettingsSection title="Login Screen" description="Estilo, fundo e frase exibidos na entrada.">
            <div className="space-y-4">
              <div>
                <Label>Estilo</Label>
                <Select
                  value={login.style}
                  onValueChange={(v) => setLogin({ ...login, style: v })}
                >
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="classic">Classic</SelectItem>
                    <SelectItem value="modern">Modern (com carousel)</SelectItem>
                    <SelectItem value="minimal">Minimal</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <Label>Tipo de Fundo</Label>
                <Select
                  value={login.backgroundType}
                  onValueChange={(v) => setLogin({ ...login, backgroundType: v })}
                >
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="solid">Cor Sólida</SelectItem>
                    <SelectItem value="gradient">Gradiente</SelectItem>
                    <SelectItem value="image">Imagem</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <Label>Slogan/Quote</Label>
                <Input
                  value={login.quote}
                  onChange={(e) => setLogin({ ...login, quote: e.target.value })}
                  placeholder="Ex: Bem-vindo ao futuro!"
                />
              </div>

              <div className="flex items-center justify-between">
                <Label>Mostrar Logo</Label>
                <Switch
                  checked={login.showLogo}
                  onCheckedChange={(c) => setLogin({ ...login, showLogo: c })}
                />
              </div>
            </div>
          </SettingsSection>
        </TabsContent>
      </Tabs>
    </SettingsPage>
  );
}
